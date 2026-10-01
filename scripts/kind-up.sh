#!/usr/bin/env bash
# Stage 2: create a local Kubernetes cluster and deploy the app to it.
# Needs: docker, kind, kubectl.  Tear down with: kind delete cluster --name job-tracker
set -euo pipefail
cd "$(dirname "$0")/.."

if ! kind get clusters | grep -q '^job-tracker$'; then
  kind create cluster --config k8s/kind-config.yaml
fi

echo "==> Installing ingress-nginx"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait -n ingress-nginx --for=condition=ready pod \
  -l app.kubernetes.io/component=controller --timeout=180s

echo "==> Installing metrics-server (needed by the HPA)"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# kind's kubelets use self-signed certs, so metrics-server must skip TLS verify.
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' || true

echo "==> Building images and loading them into kind"
docker build -t job-tracker-api:local apps/api
docker build -t job-tracker-web:local apps/web
kind load docker-image job-tracker-api:local job-tracker-web:local --name job-tracker

echo "==> Deploying"
kubectl apply -k k8s/overlays/local
kubectl -n job-tracker rollout status deploy/api --timeout=180s
kubectl -n job-tracker rollout status deploy/web --timeout=120s

echo "Done: open http://job-tracker.localtest.me"
