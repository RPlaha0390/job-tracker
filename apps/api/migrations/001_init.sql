CREATE TABLE IF NOT EXISTS applications (
  id          SERIAL PRIMARY KEY,
  company     TEXT NOT NULL,
  role        TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'applied'
              CHECK (status IN ('applied', 'interviewing', 'offer', 'rejected')),
  applied_on  DATE NOT NULL DEFAULT CURRENT_DATE,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
