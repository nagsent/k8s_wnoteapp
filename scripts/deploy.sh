#!/usr/bin/env bash
# Scenario 1 — local Kubernetes YAML via Kustomize on Docker Desktop.
# Note: builds notes-backend:local locally; no Docker Hub login or image push is needed.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

for required_command in docker kubectl; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    echo "Error: ${required_command} is required for the local Kubernetes YAML scenario." >&2
    exit 1
  fi
done

CURRENT_CONTEXT="$(kubectl config current-context)"
if [[ "${CURRENT_CONTEXT}" != "docker-desktop" ]]; then
  echo "Error: refusing to deploy to Kubernetes context '${CURRENT_CONTEXT}'." >&2
  echo "Switch to Docker Desktop Kubernetes with: kubectl config use-context docker-desktop" >&2
  exit 1
fi

docker info >/dev/null
docker build \
  --tag notes-backend:local \
  --file "${REPO_ROOT}/k8s/backend/Dockerfile" \
  "${REPO_ROOT}/k8s/backend"
kubectl apply -k "${REPO_ROOT}/k8s"
kubectl rollout status deployment/backend-api-dep --namespace webappns
