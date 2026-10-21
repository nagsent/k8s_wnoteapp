#!/usr/bin/env bash
set -euo pipefail

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME before running this script}"
docker build -t "${DOCKERHUB_USERNAME}/notes-backend:latest" \
  -f k8s/backend/Dockerfile k8s/backend
docker push "${DOCKERHUB_USERNAME}/notes-backend:latest"
