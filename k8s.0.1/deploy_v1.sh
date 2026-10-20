#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="web-app-ns"
LOCAL_PORT="${LOCAL_PORT:-8080}"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Error: kubectl is required." >&2
  exit 1
fi

echo "Deploying the notes app to namespace ${NAMESPACE}..."
kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"
kubectl apply -f "${SCRIPT_DIR}/db-config-secret.yaml"
kubectl apply -f "${SCRIPT_DIR}/postgres-sts-svc.yaml"
kubectl apply -f "${SCRIPT_DIR}/backend-configmap.yaml"
kubectl apply -f "${SCRIPT_DIR}/backend-dep-svc.yaml"
kubectl apply -f "${SCRIPT_DIR}/frontend-configmap.yaml"
kubectl apply -f "${SCRIPT_DIR}/frontend-dep-svc.yaml"

echo "Waiting for PostgreSQL and application pods..."
kubectl rollout status statefulset/postgres-sts -n "${NAMESPACE}" --timeout=180s
kubectl rollout status deployment/backend-api-dep -n "${NAMESPACE}" --timeout=180s
kubectl rollout status deployment/frontend-nginx-dep -n "${NAMESPACE}" --timeout=180s

echo "The app is available at http://localhost:${LOCAL_PORT} while this command runs."
echo "Press Ctrl-C to stop port forwarding; the Kubernetes workloads will keep running."
kubectl port-forward --address 127.0.0.1 -n "${NAMESPACE}" \
  "svc/frontend-nginx-svc" "${LOCAL_PORT}:80"
