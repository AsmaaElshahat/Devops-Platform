#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-devops-platform}"

helm uninstall grafana --namespace monitoring --ignore-not-found
helm uninstall prometheus --namespace monitoring --ignore-not-found
helm uninstall loki --namespace logging --ignore-not-found
helm uninstall vault --namespace vault --ignore-not-found
helm uninstall ingress-nginx --namespace ingress --ignore-not-found

kind delete cluster --name "$CLUSTER_NAME"

