# Simple Notes App — Kubernetes Deployment

A complete Kubernetes-based web application:

- **Frontend:** Nginx serving static HTML/JS
- **Backend:** Python Flask API
- **Database:** PostgreSQL StatefulSet
- **Ingress:** Routing `/` to frontend and `/api` to backend

## Project Structure

simple-notes-app/
├── k8s/
│   ├── namespace.yaml
│   ├── frontend/
│   ├── backend/
│   ├── db/
│   ├── ingress.yaml
├── scripts/
│   ├── deploy.sh
└── README.md


## Requirements

- Kubernetes cluster
- kubectl
- Nginx Ingress Controller
- DNS entry or `/etc/hosts`:


## Deploy

chmod +x scripts/deploy.sh
./scripts/deploy.sh


## Access

Open:

http://notes.local/


## Cleanup

kubectl delete namespace web_app_ns


