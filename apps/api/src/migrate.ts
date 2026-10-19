import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "migrations");
for (const file of (await readdir(dir)).filter((f) => f.endsWith(".sql")).sort()) {
  await client.query(await readFile(path.join(dir, file), "utf8"));
  console.log(JSON.stringify({ level: "info", msg: "migration applied", file }));
}

await client.end();
// If anything above throws, Node exits with a non-zero code,
// which tells Kubernetes the Job failed, so it retries.