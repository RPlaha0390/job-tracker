// Stage 6: generate load and watch the HPA scale the API.
//   k6 run load/k6.js
//   kubectl -n job-tracker get hpa api --watch     (in another terminal)
import http from "k6/http";
import { check, sleep } from "k6";

const BASE = __ENV.BASE_URL || "http://job-tracker.localtest.me";

export const options = {
  stages: [
    { duration: "30s", target: 20 },
    { duration: "2m", target: 100 },
    { duration: "30s", target: 0 },
  ],
  thresholds: { http_req_duration: ["p(95)<500"] },
};

export default function () {
  const res = http.get(`${BASE}/api/applications`);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(0.1);
}
