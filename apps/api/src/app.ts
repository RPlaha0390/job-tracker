import express from "express";
import type { Pool } from "pg";
import { validateNewApplication } from "./validate.js";

export function createApp(pool: Pool) {
  const app = express();
  app.use(express.json());

  // Liveness: "is the process alive?" Keep it dependency-free, otherwise a DB
  // outage makes Kubernetes restart every pod (which doesn't fix the DB).
  app.get("/healthz", (_req, res) => {
    res.json({ ok: true });
  });

  // Readiness: "can I serve traffic right now?" Failing this removes the pod
  // from the Service's endpoints without restarting it.
  app.get("/readyz", async (_req, res) => {
    try {
      await pool.query("SELECT 1");
      res.json({ ok: true });
    } catch {
      res.status(503).json({ ok: false });
    }
  });

  app.get("/api/applications", async (_req, res, next) => {
    try {
      const { rows } = await pool.query(
        "SELECT * FROM applications ORDER BY applied_on DESC, id DESC",
      );
      res.json(rows);
    } catch (err) {
      next(err);
    }
  });

  app.post("/api/applications", async (req, res, next) => {
    const error = validateNewApplication(req.body);
    if (error) return res.status(400).json({ error });
    const { company, role, status = "applied", notes = null } = req.body;
    try {
      const { rows } = await pool.query(
        `INSERT INTO applications (company, role, status, notes)
         VALUES ($1, $2, $3, $4) RETURNING *`,
        [company.trim(), role.trim(), status, notes],
      );
      res.status(201).json(rows[0]);
    } catch (err) {
      next(err);
    }
  });

  app.patch("/api/applications/:id", async (req, res, next) => {
    const { status } = req.body ?? {};
    const error = validateNewApplication({ company: "x", role: "x", status });
    if (!status || error) return res.status(400).json({ error: error ?? "status is required" });
    try {
      const { rows } = await pool.query(
        "UPDATE applications SET status = $1 WHERE id = $2 RETURNING *",
        [status, req.params.id],
      );
      if (!rows[0]) return res.status(404).json({ error: "not found" });
      res.json(rows[0]);
    } catch (err) {
      next(err);
    }
  });

  // TODO(stretch): GET /metrics with prom-client so Prometheus can scrape
  // request counts and latency (stage 6).

  app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
    console.error(JSON.stringify({ level: "error", msg: err.message }));
    res.status(500).json({ error: "internal error" });
  });

  return app;
}
