#!/usr/bin/env bash
# Scenario 3 — deploy the Helm chart to the current Kubernetes context.
# Note: install Helm 3 and push both Docker Hub images first; pass DOCKERHUB_USERNAME.
set -euo pipefail

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME to the Docker Hub account containing both app images}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v helm >/dev/null 2>&1; then
  echo "Error: Helm 3 is required. Install Helm before running this script." >&2
  exit 1
fi

helm upgrade --install notes-app "${SCRIPT_DIR}" \
  --set-string "backend.image=${DOCKERHUB_USERNAME}/notes-backend:latest" \
  --set-string "frontend.image=${DOCKERHUB_USERNAME}/notes-frontend:latest" \
  "$@"
