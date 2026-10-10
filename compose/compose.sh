#!/usr/bin/env bash
# Scenario 1 — Docker Compose.
# Note: runs the app locally; it does not deploy to Kubernetes.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
docker compose -f "${SCRIPT_DIR}/docker-compose.yaml" up --build
