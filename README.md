# Simple Notes App

A notes application with an Nginx frontend, Flask API, and PostgreSQL database.
Kubernetes resources use the DNS-valid namespace `webappns`.

## Implementations

Choose one deployment path:

| Scenario | Location | Use |
| --- | --- | --- |
| Docker Compose | [compose/](./compose/) and [compose/compose.sh](./compose/compose.sh) | Run the full stack locally without Kubernetes. |
| YAML-only Kubernetes deploy | [k8s/](./k8s/) and [scripts/deploy.sh](./scripts/deploy.sh) | Deploy PostgreSQL, the backend container image, and the frontend served from a ConfigMap with `kubectl apply -k`; no Docker Compose is used. |
| Helm | [helm/notes-app/](./helm/notes-app/) and [helm/notes-app/deploy.sh](./helm/notes-app/deploy.sh) | Install the app as a configurable Helm release. |
| CI/CD | [workflow/ci-cd.yaml](./workflow/ci-cd.yaml) | Build and push frontend/backend images, then deploy both images to Kubernetes on pushes to `main` or manual workflow dispatch. |

These are alternatives; do not apply the raw Kubernetes manifests and Helm chart
to the same namespace at the same time because they create resources with
overlapping names.

## Requirements

- Docker Engine with the Docker Compose plugin for the Compose scenario
- A Kubernetes cluster and `kubectl` for Kubernetes scenarios
- An Nginx Ingress Controller to use `notes.local` through Ingress
- Helm 3 for the Helm scenario
- A Docker Hub account for the raw-manifest and CI/CD scenarios

## Scenario 1: Docker Compose

**Note:** This scenario runs the app locally with Docker Compose. It does not
deploy to Kubernetes. Run the scenario script from the repository root:

```bash
bash compose/compose.sh
```

Open <http://localhost:8080>. The backend is also available at
<http://localhost:5000/api/notes>. Stop the stack with:

```bash
docker compose -f compose/docker-compose.yaml down
```

Add `--volumes` to `down` only if you also want to remove the local PostgreSQL
data.

## Scenario 2: Raw Kubernetes manifests

**Note:** This scenario deploys Kubernetes YAML directly with Kustomize; it does
not use Docker Compose or Helm. The frontend is served from a ConfigMap, so only
the backend image needs to be built and pushed. Set its Docker Hub image under `images` in
[k8s/kustomization.yaml](./k8s/kustomization.yaml) (`newName`) before deploying.
The default is `your-dockerhub-user/notes-backend:latest`.

Build and publish the backend image (PowerShell example):

```powershell
$env:DOCKERHUB_USERNAME = "your-dockerhub-user"
docker login
docker build -t "$env:DOCKERHUB_USERNAME/notes-backend:latest" `
  -f .\k8s\backend\Dockerfile .\k8s\backend
docker push "$env:DOCKERHUB_USERNAME/notes-backend:latest"
```

The equivalent Bash build commands are:

```sh
export DOCKERHUB_USERNAME=your-dockerhub-user
docker login
bash k8s/backend/docker.sh
```

Set `newName` in `k8s/kustomization.yaml` to the literal image name for your
account (for example, `my-dockerhub-user/notes-backend`). Then run the
deployment script from the repository root (Git Bash or WSL on Windows):

```bash
bash scripts/deploy.sh
```

It applies all Kubernetes resources with Kustomize and waits for the backend
rollout.

The PostgreSQL Secret in the sample manifests is for local/demo use; replace it
with a securely managed secret before using this outside a disposable
environment.

The Ingress host is `notes.local`. Point it at your cluster's ingress address
(for example, by adding an appropriate entry to `/etc/hosts`) and open
<http://notes.local>. Alternatively, use `kubectl port-forward` against the
frontend service in `webappns`:

```sh
kubectl port-forward -n webappns svc/frontend-nginx-svc 8080:80
```

Then open <http://localhost:8080>.

## Scenario 3: Helm

**Note:** This scenario installs the Helm chart to the currently selected
Kubernetes context. It is separate from the raw YAML scenario; do not install
both into the same namespace. The deployment script expects Helm 3 and already
published frontend/backend Docker Hub images.

Install Helm 3 using its official instructions:
<https://helm.sh/docs/intro/install/>.
On Windows, install with `winget` from PowerShell:

```powershell
winget install Helm.Helm
helm version
```

Alternatively, use the official Windows binary download instructions linked
above. On macOS with Homebrew:

```sh
brew install helm
helm version
```

Publish both application images:

```sh
export DOCKERHUB_USERNAME=your-dockerhub-user
docker login
bash k8s/backend/docker.sh
bash k8s/frontend/docker.sh
```

Install or upgrade the release from the repository root. In PowerShell use
`bash helm/notes-app/deploy.sh` (Git Bash or WSL); supply the Docker Hub account:

```powershell
$env:DOCKERHUB_USERNAME = "your-dockerhub-user"
bash .\helm\notes-app\deploy.sh
```

The Bash script accepts additional Helm arguments after its image settings. To
install or upgrade manually instead:

```sh
helm upgrade --install notes-app ./helm/notes-app \
  --set backend.image="$DOCKERHUB_USERNAME/notes-backend:latest" \
  --set frontend.image="$DOCKERHUB_USERNAME/notes-frontend:latest"
```

The default chart uses HTTP and creates `webappns`. To enable TLS, install an
Nginx Ingress Controller and cert-manager first. For cert-manager, follow its
official installation guide or apply its current release manifest:

```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl rollout status deployment/cert-manager -n cert-manager
```

Then set a real email address and a public DNS name you control (the default
`notes.local` cannot receive a public Let's Encrypt certificate):

```sh
helm upgrade --install notes-app ./helm/notes-app \
  --set backend.image="$DOCKERHUB_USERNAME/notes-backend:latest" \
  --set frontend.image="$DOCKERHUB_USERNAME/notes-frontend:latest" \
  --set ingress.tls=true \
  --set ingress.host=notes.example.com \
  --set ingress.email=you@example.com
```

Uninstall the release with `helm uninstall notes-app`. The chart-managed
namespace is a separate Kubernetes resource and may remain after uninstall.

## Scenario 4: GitHub Actions CI/CD

**Note:** This scenario is executed by GitHub Actions, not by a local deployment
script. It builds and pushes images and deploys them when code is pushed to
`main` or the workflow is manually dispatched.

The workflow in [workflow/ci-cd.yaml](./workflow/ci-cd.yaml) builds and publishes
both images, then deploys them when code is pushed to `main` or the workflow is
manually dispatched. Add these repository Actions secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `KUBECONFIG` (the target cluster's kubeconfig content)

The workflow uses the raw Kubernetes database and Ingress manifests, but selects
the image-based frontend deployment for CI.

## Optional tools

### Prometheus and Grafana

The Helm chart can create a `ServiceMonitor` when the Prometheus Operator CRD is
installed. Install the monitoring stack first:

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

Then upgrade the app with monitoring enabled:

```sh
helm upgrade --install notes-app ./helm/notes-app \
  --set backend.image="$DOCKERHUB_USERNAME/notes-backend:latest" \
  --set frontend.image="$DOCKERHUB_USERNAME/notes-frontend:latest" \
  --set monitoring.enabled=true
```

Forward Grafana's service and log in using the credentials configured for your
monitoring release:

```sh
kubectl get svc -n monitoring
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

The chart's ServiceMonitor expects the Prometheus release label
`kube-prometheus-stack` and the monitoring namespace `monitoring`.

### TLS with cert-manager

TLS is optional and is disabled by default. The chart creates its Let's Encrypt
`ClusterIssuer` and TLS Ingress only when `ingress.tls=true`. cert-manager,
Nginx Ingress, and a reachable DNS name for the configured host must be
available before enabling TLS. `notes.local` is intended for local testing and
cannot receive a public Let's Encrypt certificate.

## Cleanup

For raw Kubernetes resources:

```sh
kubectl delete namespace webappns
```

For Helm, run `helm uninstall notes-app`; remove `webappns` separately if it is
no longer needed. For Compose, run the `docker compose ... down` command above.
