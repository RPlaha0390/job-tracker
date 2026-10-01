import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";
import { createApp } from "./app.js";

const PORT = Number(process.env.PORT ?? 3000);
const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error("DATABASE_URL is not set");
  process.exit(1);
}

const pool = new pg.Pool({ connectionString: DATABASE_URL, max: 10 });

// Runs every .sql file in /migrations on startup. Simple, but with several
// replicas they all race to migrate at once.
// TODO(stage 2 decision): move this into a Kubernetes Job or an initContainer
// and write up the trade-off in docs/decisions.md.
async function migrate() {
  const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "migrations");
  for (const file of (await readdir(dir)).filter((f) => f.endsWith(".sql")).sort()) {
    await pool.query(await readFile(path.join(dir, file), "utf8"));
    console.log(JSON.stringify({ level: "info", msg: "migration applied", file }));
  }
}

await migrate();
const server = createApp(pool).listen(PORT, () => {
  console.log(JSON.stringify({ level: "info", msg: "api listening", port: PORT }));
});

// Kubernetes sends SIGTERM before killing a pod. Stop accepting new requests,
// finish in-flight ones, then close DB connections. This is what makes rolling
// deploys zero-downtime.
process.on("SIGTERM", () => {
  console.log(JSON.stringify({ level: "info", msg: "SIGTERM received, shutting down" }));
  server.close(() => pool.end().then(() => process.exit(0)));
});
