#!/usr/bin/env bash
set -euo pipefail

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME to the Docker Hub account containing notes-backend}"

echo "Deploying Simple Notes App..."

kubectl apply -f k8s/namespace.yaml

kubectl apply -f k8s/db/db-configmap.yaml
kubectl apply -f k8s/db/db-secret.yaml
kubectl apply -f k8s/db/postgres-service.yaml
kubectl apply -f k8s/db/postgres-statefulset.yaml

kubectl apply -f k8s/backend/backend-deployment.yaml
kubectl set image deployment/backend-api-dep \
  "backend-api=${DOCKERHUB_USERNAME}/notes-backend:latest" \
  --namespace webappns
kubectl apply -f k8s/backend/backend-service.yaml

kubectl apply -f k8s/frontend/frontend-configmap.yaml
kubectl apply -f k8s/frontend/frontend-deployment.yaml
kubectl apply -f k8s/frontend/frontend-service.yaml

kubectl apply -f k8s/ingress.yaml

kubectl rollout status deployment/backend-api-dep --namespace webappns
echo "Deployment completed successfully."
