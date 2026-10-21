#!/usr/bin/env bash

set -e

echo "Creating namespace..."
kubectl apply -f namespace.yaml

echo "Applying database config and secrets..."
kubectl apply -f db-config-secret.yaml

echo "Deploying PostgreSQL StatefulSet and Service..."
kubectl apply -f postgres-sts-svc.yaml

echo "Deploying backend API (Flask)..."
kubectl apply -f backend-configmap.yaml
kubectl apply -f backend-dep-svc.yaml

echo "Deploying frontend (Nginx)..."
kubectl apply -f frontend-configmap.yaml
kubectl apply -f frontend-dep-svc.yaml

echo "Applying Ingress..."
kubectl apply -f ingress.yaml

echo "All components deployed in namespace web_app_ns."

kubectl port-forward -n web-app-ns svc/frontend-nginx-svc 8080:80