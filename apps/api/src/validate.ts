export const STATUSES = ["applied", "interviewing", "offer", "rejected"] as const;
export type Status = (typeof STATUSES)[number];

export interface NewApplication {
  company: string;
  role: string;
  status?: Status;
  notes?: string;
}

/** Returns an error message, or null if the body is valid. */
export function validateNewApplication(body: unknown): string | null {
  if (typeof body !== "object" || body === null) return "body must be an object";
  const b = body as Record<string, unknown>;
  if (typeof b.company !== "string" || !b.company.trim()) return "company is required";
  if (typeof b.role !== "string" || !b.role.trim()) return "role is required";
  if (b.status !== undefined && !STATUSES.includes(b.status as Status)) {
    return `status must be one of ${STATUSES.join(", ")}`;
  }
  return null;
}
