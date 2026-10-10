#!/usr/bin/env bash
# Scenario 2 — raw Kubernetes YAML via Kustomize.
# Note: set the backend image in k8s/kustomization.yaml and push it to Docker Hub first.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Error: kubectl is required for the raw Kubernetes YAML scenario." >&2
  exit 1
fi

kubectl apply -k "${REPO_ROOT}/k8s"
kubectl rollout status deployment/backend-api-dep --namespace webappns
