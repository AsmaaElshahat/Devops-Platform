# DevOps Integration Platform — Project Plan

## Project Overview

A production-style local DevOps platform running on WSL2 that demonstrates Docker, Kubernetes, Terraform, Vault, Prometheus, Grafana, Loki, ingress/load balancing, and a Flask-based full-stack application. Designed as a portfolio project for a DevOps role.

---

## Architecture

```
Frontend (Flask UI) → Ingress → Backend API → dummy data
                              ↓
                    Prometheus (metrics)
                    Grafana (dashboards)
                    Loki (logs)
                    Vault (secrets)
```

---

## Phase 1: WSL2 Environment Setup

### Step 1.1: Install and configure WSL2
- Install Ubuntu 22.04 via WSL2 on Windows
- Update system packages: `sudo apt update && sudo apt upgrade -y`
- Install required tools: `git`, `curl`, `unzip`, `jq`, `gnupg`, `apt-transport-https`

### Step 1.2: Install Docker Desktop with WSL2 backend
- Download Docker Desktop for Windows
- Enable WSL2 integration for Ubuntu distro
- Verify: `docker --version` and `docker compose version`

### Step 1.3: Install Terraform
- Download Terraform binary from HashiCorp releases
- Place in `/usr/local/bin/`
- Verify: `terraform --version`

### Step 1.4: Install kubectl
- Install kubectl via `curl -LO` from GitHub releases
- Make executable, move to `/usr/local/bin/`
- Verify: `kubectl version --client`

### Step 1.5: Install Kind (Kubernetes in Docker)
- Download Kind binary from GitHub releases
- Place in `/usr/local/bin/`
- Verify: `kind version`

### Step 1.6: Install HashiCorp tools
- Install Vault CLI: download binary, place in `/usr/local/bin/`

---

## Phase 2: Application Development (Flask Full-Stack App)

### Step 2.1: Project structure
```
app/
├── frontend/          # Flask UI templates + static assets
├── backend/           # REST API service
├── Dockerfile
├── requirements.txt
└── config.py
```

### Step 2.2: Backend API
- Flask REST API with endpoints: `/api/health`, `/api/tasks`, `/api/metrics`
- Connects to PostgreSQL for data persistence
- verify user data from Vault
- Exposes Prometheus metrics via `prometheus_flask_exporter`

### Step 2.3: Frontend UI
- Flask templates with Jinja2
- Dashboard showing: system health, metrics summary
- Static assets: CSS, JS for interactivity

### Step 2.4: Dockerfile
- Multi-stage build for the Flask app
- Python 3.11-slim base image
- Copy dependencies, install via pip
- Copy application code, set entrypoint

### Step 2.5: Docker Compose (local dev)
- Services: frontend, backend, prometheus, grafana
- Networks and volume definitions
- Environment variables for configuration
- Used for local development before Kubernetes deployment

---

## Phase 3: Terraform Infrastructure

### Step 3.1: Terraform project structure
```
infrastructure/
├── main.tf            # Provider and resource definitions
├── variables.tf       # Input variables
├── outputs.tf         # Output values
├── providers.tf       # Provider configurations
└── kind-cluster.tf    # Kind cluster provisioning
```

### Step 3.2: Terraform provider setup
- Use `docker` provider to manage Docker resources
- Use `kind` via null_resource with local-exec provisioners
- Define variables for cluster name, node count, port mappings

### Step 3.3: Kind cluster provisioning
- Terraform creates a Kind cluster config with:
  - Extra port mappings for services (Vault, Grafana, Prometheus)
  - Kubernetes 1.28+
  - Worker nodes if needed
- `terraform apply` provisions the cluster
- `terraform destroy` tears it down

### Step 3.4: Kubernetes manifests via Terraform
- Use `kubectl` provider or `helm` provider
- Deploy Helm charts for:
  - Prometheus operator (kube-prometheus-stack)
  - Grafana
  - Vault (HashiCorp Vault Helm chart)
  - Ingress NGINX controller
  - Loki (Grafana Loki Helm chart)

---

## Phase 4: Kubernetes Cluster Setup

### Step 4.1: Create Kind cluster
- Write `kind-config.yaml` with port mappings:
  - 8080:80 (ingress HTTP)
  - 8443:443 (ingress HTTPS)
  - 8200:8200 (Vault)
  - 3000:3000 (Grafana)
  - 9090:9090 (Prometheus)
  - 3100:3100 (Loki)
- Run: `kind create cluster --config kind-config.yaml`

### Step 4.2: Install Helm
- Download and install Helm binary
- Add required repositories:
  - `bitnami`
  - `hashicorp`
  - `grafana`
  - `prometheus-community`
  - `ingress-nginx`

### Step 4.3: Deploy Vault
- `helm install vault hashicorp/vault --namespace vault --create-namespace`
- Configure Vault with file
- Unseal Vault and enable KV secrets engine
- Store API keys in Vault

### Step 4.4: Deploy Prometheus + Grafana
- `helm install prometheus grafana/kube-prometheus-stack --namespace monitoring --create-namespace`
- Configure service monitors for app services
- Configure Grafana dashboards via ConfigMap

### Step 4.5: Deploy Loki
- `helm install loki grafana/loki --namespace logging --create-namespace`
- Configure Promtail/FluentBit as log collector sidecar
- Point app pods to push logs to Loki

### Step 4.6: Deploy Ingress NGINX
- `helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress`
- Configure ingress resource for the Flask app
- Set up load balancing across app replicas

---

## Phase 5: Application Deployment on Kubernetes

### Step 5.1: Build and load Docker image
- Build Flask app Docker image locally
- Load into Kind cluster: `kind load docker-image flask-app:latest`

### Step 5.2: Kubernetes manifests
```
k8s/
├── namespace.yaml
├── deployment.yaml       # Flask app deployment (frontend + backend)
├── service.yaml          # ClusterIP services
├── ingress.yaml          # Ingress resource
├── configmap.yaml        # App configuration
├── secret.yaml           # Or Vault Agent injector
├── servicemonitor.yaml   # Prometheus service monitor
└── pvc.yaml              # Persistent volumes if needed
```

### Step 5.3: Vault Agent injection
- Annotate deployment pods with Vault Agent sidecar injection
- Configure Vault Agent to inject secrets as files or env vars
- App reads DB credentials from injected secrets

### Step 5.4: Ingress configuration
- Define Ingress resource routing traffic to Flask app
- Configure host-based routing: `app.local`
- Test load balancing with multiple replicas

### Step 5.5: Prometheus scraping
- Create ServiceMonitor for Flask app `/metrics` endpoint
- Verify metrics appear in Prometheus UI

### Step 5.6: Loki log collection
- Configure Promtail DaemonSet or FluentBit
- App logs go to stdout, collected by sidecar, sent to Loki
- Query logs via Grafana Explore

---

## Phase 6: Monitoring and Observability

### Step 6.1: Grafana dashboards
- Import or create dashboards for:
  - Application metrics (request rate, latency, errors)
  - Kubernetes cluster health
  - Vault status

### Step 6.2: Prometheus alerts
- Configure alerting rules for:
  - High error rate
  - Pod restarts
  - Memory/CPU thresholds
  - Disk pressure

### Step 6.3: Loki log queries
- Set up log labels for app, backend, worker
- Create Grafana log panels
- Correlate logs with metrics

---

## Phase 7: Testing and Validation

### Step 7.1: Functional tests
- Test API endpoints via curl or Postman
- Verify database connectivity
- Confirm task processing by worker

### Step 7.2: Secret management test
- Verify Vault Agent injects secrets correctly
- Confirm app reads DB credentials from Vault
- Test secret rotation

### Step 7.3: Service discovery test
- Confirm services discover each other

### Step 7.4: Load balancing test
- Scale deployment to 3 replicas
- Verify Ingress distributes requests
- Test with `ab` or `wrk` load testing tool

### Step 7.5: Monitoring validation
- Confirm metrics appear in Prometheus
- Verify Grafana dashboards render data
- Check Loki log aggregation works

### Step 7.6: Terraform validation
- Run `terraform plan` to verify no drift
- Test `terraform destroy` and `terraform apply` cycle

---

## Phase 8: Documentation and GitHub Repository

### Step 8.1: Repository structure
```
DevOpsIntegration/
├── app/                  # Flask application code
├── infrastructure/       # Terraform configurations
├── k8s/                  # Kubernetes manifests
├── docker/               # Dockerfiles and compose
├── monitoring/           # Grafana dashboards, alert rules
├── scripts/              # Helper scripts (setup, deploy)
├── docs/                 # Architecture diagrams, runbook
├── README.md             # Project overview and setup guide
└── plan.md               # This plan
```

### Step 8.2: README content
- Project overview and architecture diagram
- Prerequisites (WSL2, Docker Desktop)
- Step-by-step setup instructions
- How to run locally with Docker Compose
- How to deploy to Kind cluster
- How to access services (URLs, ports)
- How to destroy the environment

### Step 8.3: Architecture diagram
- Create visual diagram (draw.io or Mermaid) showing all components
- Include data flow between services

### Step 8.4: GitHub setup
- Initialize repository, add all files
- Write comprehensive README
- Add `.gitignore` for secrets, local state files
- Create GitHub repository and push

---

## Execution Order

1. **Phase 1** — Set up WSL2 environment and install all tools
2. **Phase 2** — Develop Flask application
3. **Phase 3** — Write Terraform infrastructure code
4. **Phase 4** — Deploy Kind cluster and install all tools (Vault, Prometheus, Grafana, Loki, Ingress)
5. **Phase 5** — Deploy Flask app to Kubernetes with Vault secrets, Ingress routing
6. **Phase 6** — Configure monitoring dashboards and alerts
7. **Phase 7** — Test everything end-to-end
8. **Phase 8** — Document, push to GitHub, prepare for CV

---

## Key Technologies Demonstrated

| Technology      | Usage in Project                                    |
|----------------|-----------------------------------------------------|
| Docker         | Containerize Flask app, Kind cluster nodes          |
| Kubernetes     | Orchestrate all services on Kind cluster            |
| Terraform      | Provision Kind cluster, deploy Helm charts          |
| Vault          | Store  API keys                                     |
| Prometheus     | Scrape metrics from all services                    |
| Grafana        | Visualize metrics and logs in dashboards            |
| Loki           | Centralized log aggregation                         |
| Ingress NGINX  | Load balancing and external access to Flask app     |
