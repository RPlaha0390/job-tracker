import { FormEvent, useEffect, useState } from "react";

type Status = "applied" | "interviewing" | "offer" | "rejected";
interface Application {
  id: number;
  company: string;
  role: string;
  status: Status;
  applied_on: string;
}

const STATUSES: Status[] = ["applied", "interviewing", "offer", "rejected"];

export function App() {
  const [apps, setApps] = useState<Application[]>([]);
  const [company, setCompany] = useState("");
  const [role, setRole] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function load() {
    try {
      const res = await fetch("/api/applications");
      if (!res.ok) throw new Error(`API returned ${res.status}`);
      setApps(await res.json());
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function add(e: FormEvent) {
    e.preventDefault();
    const res = await fetch("/api/applications", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ company, role }),
    });
    if (!res.ok) return setError((await res.json()).error);
    setCompany("");
    setRole("");
    load();
  }

  async function setStatus(id: number, status: Status) {
    await fetch(`/api/applications/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status }),
    });
    load();
  }

  return (
    <main style={{ fontFamily: "system-ui", maxWidth: 720, margin: "2rem auto", padding: "0 1rem" }}>
      <h1>Job Tracker</h1>
      {/* Handy during demos: shows which build is live after a deploy. */}
      <p style={{ color: "#666" }}>version: {import.meta.env.VITE_APP_VERSION ?? "dev"}</p>

      <form onSubmit={add} style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <input placeholder="Company" value={company} onChange={(e) => setCompany(e.target.value)} />
        <input placeholder="Role" value={role} onChange={(e) => setRole(e.target.value)} />
        <button type="submit">Add</button>
      </form>

      {error && <p style={{ color: "crimson" }}>{error}</p>}

      <table width="100%" cellPadding={6}>
        <thead>
          <tr style={{ textAlign: "left" }}>
            <th>Company</th>
            <th>Role</th>
            <th>Applied</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {apps.map((a) => (
            <tr key={a.id}>
              <td>{a.company}</td>
              <td>{a.role}</td>
              <td>{a.applied_on.slice(0, 10)}</td>
              <td>
                <select value={a.status} onChange={(e) => setStatus(a.id, e.target.value as Status)}>
                  {STATUSES.map((s) => (
                    <option key={s}>{s}</option>
                  ))}
                </select>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
