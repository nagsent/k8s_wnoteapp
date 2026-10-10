#!/usr/bin/env bash
set -e

echo "Deploying Simple Notes App..."

kubectl apply -f k8s/namespace.yaml

kubectl apply -f k8s/db/db-configmap.yaml
kubectl apply -f k8s/db/db-secret.yaml
kubectl apply -f k8s/db/postgres-service.yaml
kubectl apply -f k8s/db/postgres-statefulset.yaml

kubectl apply -f k8s/backend/backend-configmap.yaml
kubectl apply -f k8s/backend/backend-deployment.yaml
kubectl apply -f k8s/backend/backend-service.yaml

kubectl apply -f k8s/frontend/frontend-configmap.yaml
kubectl apply -f k8s/frontend/frontend-deployment.yaml
kubectl apply -f k8s/frontend/frontend-service.yaml

kubectl apply -f k8s/ingress.yaml

echo "Deployment completed successfully."

