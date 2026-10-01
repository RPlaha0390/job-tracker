# Decision log

One entry per meaningful choice. This is what you present. Being able to explain
*why*, and what you gave up, matters more than the choice itself.

Template:

```
## N. <Decision>
**Context:** what problem / constraint
**Options considered:** A, B, C
**Decision:** B
**Why:** ...
**Trade-off / what we gave up:** ...
**Would revisit if:** ...
```

---

## Example: 0. Liveness and readiness probes check different things

**Context:** Kubernetes needs to know if a pod is alive and if it can take traffic.
**Options considered:** (a) one endpoint that checks the DB for both; (b) separate endpoints.
**Decision:** (b). `/healthz` checks only the process; `/readyz` also checks the DB.
**Why:** if liveness checked the DB, a DB outage would make Kubernetes restart
every API pod in a loop. That makes things worse and doesn't fix the DB.
Failing readiness just takes pods out of the load balancer until the DB is back.
**Trade-off:** during a DB outage the pods stay "alive" but serve nothing. Acceptable.
**Would revisit if:** the API gained features that work without the DB.

---

## Fill these in as you go

1. Multi-stage Dockerfile vs single stage (image size, attack surface)
2. nginx serving the React build vs a Node server
3. Kustomize vs Helm
4. Migrations: on app startup vs Kubernetes Job vs initContainer
5. CPU limits: set them or not?
6. Postgres in-cluster (StatefulSet) vs RDS
7. Single NAT gateway vs one per AZ (cost vs resilience)
8. Secrets: Kubernetes Secret in git vs Sealed Secrets vs External Secrets + AWS Secrets Manager
9. CI pushes to the cluster vs GitOps (Argo CD pulls from git)
10. GitHub OIDC vs long-lived AWS access keys in CI
11. Image tags: `latest` vs git SHA (and why ECR is set to IMMUTABLE)
12. Rolling update vs blue/green vs canary
