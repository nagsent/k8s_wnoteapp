#!/usr/bin/env bash
# Scenario 1 — YAML deployment to Docker Desktop Kubernetes.
# Note: configure a public Docker Hub backend image in k8s/kustomization.yaml; no login or Compose is used.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Error: kubectl is required for the Docker Desktop Kubernetes scenario." >&2
  exit 1
fi

CURRENT_CONTEXT="$(kubectl config current-context)"
if [[ "${CURRENT_CONTEXT}" != "docker-desktop" ]]; then
  echo "Error: refusing to deploy to Kubernetes context '${CURRENT_CONTEXT}'." >&2
  echo "Switch to Docker Desktop Kubernetes with: kubectl config use-context docker-desktop" >&2
  exit 1
fi

if ! RENDERED_MANIFESTS="$(kubectl kustomize "${REPO_ROOT}/k8s" 2>&1)"; then
  echo "Error: could not render the Kubernetes manifests." >&2
  echo "${RENDERED_MANIFESTS}" >&2
  exit 1
fi

if grep -q 'your-dockerhub-user' <<< "${RENDERED_MANIFESTS}"; then
  echo "Error: set images[0].newName in k8s/kustomization.yaml to your public Docker Hub backend image." >&2
  echo "Example: docker.io/myaccount/notes-backend" >&2
  exit 1
fi

kubectl apply -k "${REPO_ROOT}/k8s"
kubectl rollout status deployment/backend-api-dep --namespace webappns --timeout=180s
