#!/usr/bin/env bash
set -euo pipefail

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME before running this script}"
docker build -t "${DOCKERHUB_USERNAME}/notes-frontend:latest" \
  -f k8s/frontend/Dockerfile k8s/frontend
docker push "${DOCKERHUB_USERNAME}/notes-frontend:latest"
