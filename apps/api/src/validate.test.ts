import { test } from "node:test";
import assert from "node:assert/strict";
import { validateNewApplication } from "./validate.js";

test("accepts a valid application", () => {
  assert.equal(validateNewApplication({ company: "Acme", role: "Engineer" }), null);
});

test("rejects a missing company", () => {
  assert.match(validateNewApplication({ role: "Engineer" }) ?? "", /company/);
});

test("rejects an unknown status", () => {
  assert.match(
    validateNewApplication({ company: "Acme", role: "Eng", status: "ghosted" }) ?? "",
    /status/,
  );
});

// TODO(stage 5): add an integration test that runs against a real Postgres
// (e.g. a `services: postgres` container in GitHub Actions).
