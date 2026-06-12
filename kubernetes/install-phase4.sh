#!/usr/bin/env bash
set -euo pipefail

CONTEXT="${CONTEXT:-kind-devops-platform}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl --context "$CONTEXT" get nodes

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress \
  --create-namespace \
  --values "$SCRIPT_DIR/values/ingress-nginx-values.yaml" \
  --wait \
  --timeout 15m

helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --values "$SCRIPT_DIR/values/vault-values.yaml" \
  --set 'server.dev.devRootToken=root' \
  --wait \
  --timeout 15m

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values "$SCRIPT_DIR/values/kube-prometheus-stack-values.yaml" \
  --dependency-update \
  --wait \
  --timeout 15m

helm upgrade --install loki grafana-community/loki \
  --namespace logging \
  --create-namespace \
  --values "$SCRIPT_DIR/values/loki-values.yaml" \
  --dependency-update \
  --wait \
  --timeout 15m

helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --create-namespace \
  --values "$SCRIPT_DIR/values/grafana-values.yaml" \
  --set-file "dashboards.default.backend-observability.json=$SCRIPT_DIR/../monitoring/grafana/dashboards/backend-dashboard.json" \
  --set-file "dashboards.default.request-outcomes.json=$SCRIPT_DIR/../monitoring/grafana/dashboards/request-outcomes-dashboard.json" \
  --set 'adminPassword=admin' \
  --wait \
  --timeout 15m

kubectl --context "$CONTEXT" get pods --all-namespaces
