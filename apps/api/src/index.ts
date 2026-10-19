import pg from "pg";
import { createApp } from "./app.js";

const PORT = Number(process.env.PORT ?? 3000);
const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error("DATABASE_URL is not set");
  process.exit(1);
}

const pool = new pg.Pool({ connectionString: DATABASE_URL, max: 10 });

const server = createApp(pool).listen(PORT, () => {
  console.log(JSON.stringify({ level: "info", msg: "api listening", port: PORT }));
});

process.on("SIGTERM", () => {
  console.log(JSON.stringify({ level: "info", msg: "SIGTERM received, shutting down" }));
  server.close(() => pool.end().then(() => process.exit(0)));
});
