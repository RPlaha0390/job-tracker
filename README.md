# Job Tracker: a DevOps learning project

A small React + Node + Postgres app whose real purpose is to learn **Docker,
Kubernetes, Terraform, CI/CD and system design** by deploying it properly.

The app is deliberately simple. The learning is in how it's built, shipped and run.

```
                        ┌──────────── Kubernetes (kind locally / EKS on AWS) ────────────┐
 browser ──► Ingress ──►│ web (nginx + React static) ──/api──► api (Node, 2-6 pods, HPA) │──► Postgres
                        └─────────────────────────────────────────────────────────────────┘   (StatefulSet locally,
                                                                                                RDS on AWS)
 git push ──► GitHub Actions ──► test ──► build images ──► ECR ──► kubectl apply (or Argo CD)
```

## Repo layout

| Path | What it is |
|---|---|
| `apps/api` | Node/Express API, health endpoints, graceful shutdown, multi-stage Dockerfile |
| `apps/web` | React (Vite) app served by nginx |
| `docker-compose.yml` | Stage 1: run everything locally |
| `k8s/base` | Deployments, Services, Ingress, HPA, PDB |
| `k8s/overlays/local` | kind cluster: adds in-cluster Postgres + throwaway secrets |
| `k8s/overlays/prod` | EKS: ECR images, real host |
| `scripts/kind-up.sh` | Stage 2: creates a local cluster and deploys |
| `infra/terraform` | Stage 4: AWS (state bucket, VPC, ECR, EKS, RDS, GitHub OIDC) |
| `.github/workflows/ci.yml` | Stage 5: test, build, push, deploy |
| `load/k6.js` | Stage 6: load test to show autoscaling |
| `docs/decisions.md` | **Your decision log: the most important file for the presentation** |

Search the repo for `TODO(stage N)` to find the exercises for each stage.

---

## Stage 0: Setup (1 evening)

Install: Docker Desktop, Node 22, `kubectl`, `kind`, `k6`, Terraform ≥ 1.10, AWS CLI.

```bash
cd apps/api && npm install && npm test   # creates package-lock.json (commit it)
cd ../web && npm install && npm run build
```

Push the repo to GitHub.

## Stage 1: Containers (week 1)

```bash
docker compose up --build        # then open http://localhost:8080
```

- [ ] Read both Dockerfiles line by line. Why two stages? Why `npm ci` not `npm install`? Why `USER node`?
- [ ] Compare image sizes (`docker images`) against a single-stage build
- [ ] Kill the `api` container while the app is open. What does the UI do?
- [ ] Write decisions #1–2 in `docs/decisions.md`

## Stage 2: Kubernetes locally (weeks 2–3)

```bash
./scripts/kind-up.sh             # then open http://job-tracker.localtest.me
kubectl -n job-tracker get pods,svc,ingress,hpa
```

- [ ] Explain each object in `k8s/base` without looking: Deployment, Service, Ingress, HPA, PDB
- [ ] `kubectl delete pod <api-pod>` and watch it come back (`kubectl get pods -w`)
- [ ] Break the readiness probe (wrong path). What happens? Now break liveness instead. What's different?
- [ ] Change the API and do a rolling update. Watch zero-downtime in action
- [ ] `kubectl rollout undo deploy/api`
- [ ] Move DB migrations from app startup into a Kubernetes `Job` or `initContainer` (see `apps/api/src/index.ts`)
- [ ] Decisions #3–5

## Stage 3: Packaging (week 4)

Kustomize is already used (`base` + `overlays`).

- [ ] Understand what `kubectl kustomize k8s/overlays/local` outputs vs `prod`
- [ ] Optional: convert to a Helm chart and compare. Which does work use?

## Stage 4: Terraform on AWS (weeks 5–7) ⚠️ costs money

1. Create an AWS account, enable MFA on root, create an admin IAM user/SSO login. Never use root day to day.
2. `infra/terraform/bootstrap`: state bucket + **billing alert**. Do this first.
3. `infra/terraform/envs/dev`: put the bucket name in `versions.tf`, then:
   ```bash
   terraform init
   terraform plan                  # read it! every line
   terraform apply -target=module.network -target=module.ecr
   terraform apply                 # EKS: ~15 min, and starts the meter
   $(terraform output -raw kubeconfig_command)
   terraform destroy               # at the end of EVERY session
   ```
- [ ] Write `modules/rds` yourself (instructions in the file)
- [ ] Install the AWS Load Balancer Controller so the Ingress gets a real URL
- [ ] Get `db-credentials` from Secrets Manager into the cluster (External Secrets Operator)
- [ ] Decisions #6–8

**Cost guide:** the EKS control plane, NAT gateway, nodes and RDS all bill hourly.
Check current AWS pricing before you start, keep sessions short, and destroy
afterwards. Stages 1–3 are completely free.

## Stage 5: CI/CD (week 8)

Follow the setup notes at the top of `.github/workflows/ci.yml`.

- [ ] Push a change to `main` and watch it deploy itself. The version shown in the UI should change
- [ ] Add a GitHub environment approval gate for `dev`
- [ ] Add a `terraform plan` job that comments on PRs touching `infra/`
- [ ] Stretch: GitOps with Argo CD (see the TODO at the bottom of `ci.yml`)

## Stage 6: Observability & scaling (week 9)

- [ ] Install `kube-prometheus-stack` (Helm) and open Grafana
- [ ] Add a `/metrics` endpoint to the API with `prom-client`
- [ ] `k6 run load/k6.js` while running `kubectl -n job-tracker get hpa api -w`

## Stretch: system design features

- [ ] Redis cache for `GET /api/applications`. How do you invalidate it?
- [ ] A `worker` Deployment consuming a queue (SQS or Redis) that sends follow-up reminders
- [ ] What would change at 100× traffic? At 10,000×? (read replicas, CDN for web, connection pooling…)

---

## Presenting it back (~15 min)

1. **Architecture diagram** (2 min): request path, where state lives, what's managed vs self-run
2. **Live demo** (5 min):
   - `git push` → Actions → new version live
   - delete a pod → it self-heals
   - k6 load → HPA adds pods
   - `rollout undo`
3. **Decision log** (5 min): walk through 3–4 entries from `docs/decisions.md`: the choice, the alternatives, the trade-off
4. **What I'd do next / what I'm unsure about** (3 min): ask for his opinion here. It turns the talk into mentoring.
