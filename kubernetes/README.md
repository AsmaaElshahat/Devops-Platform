# Phase 4 Kubernetes Cluster Setup

This folder contains the manual Kubernetes and Helm version of Phase 4.

Phase 3 already automates this setup with Terraform. These files show the
equivalent manual workflow without running anything automatically.

## What Is Included

- `kind-config.yaml`: Kind cluster configuration with the required local ports.
- `helm-repositories.sh`: Helm repository setup commands.
- `install-phase4.sh`: Manual install commands for the Phase 4 platform tools.
- `verify-phase4.sh`: Commands to check the cluster and services.
- `uninstall-phase4.sh`: Manual cleanup commands for the Helm releases and Kind cluster.
- `values/`: Helm values used by the install script.

## Phase 4 Tools

The manual setup installs:

- ingress-nginx
- Vault
- kube-prometheus-stack
- Grafana
- Loki

Grafana is installed as a separate Helm release, matching the Terraform setup in
`infrastructure/helm-releases.tf`.

## Manual Usage

Run these only if you want to perform Phase 4 manually.

```bash
cd kubernetes

# Create the Kind cluster.
kind create cluster --name devops-platform --config kind-config.yaml

# Add Helm repositories.
bash helm-repositories.sh

# Install the platform charts.
bash install-phase4.sh

# Verify everything.
bash verify-phase4.sh
```

## Local URLs

After the manual install completes:

```text
Ingress HTTP:  http://localhost:8080
Ingress HTTPS: https://localhost:8443
Vault:         http://localhost:8200
Grafana:       http://localhost:3000
Prometheus:    http://localhost:9090
Loki:          http://localhost:3100
```

Default local credentials:

```text
Grafana username: admin
Grafana password: admin
Vault root token: root
```

## Important

Do not run Phase 3 Terraform and Phase 4 manual installation against the same
cluster unless you know exactly what you are changing. They manage the same
tools, just with different methods.

For this project:

```text
Phase 3 = automated Terraform setup
Phase 4 = manual Kubernetes and Helm setup
```

