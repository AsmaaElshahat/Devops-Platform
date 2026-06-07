#!/usr/bin/env bash
set -euo pipefail

CONTEXT="${CONTEXT:-kind-devops-platform}"

kubectl --context "$CONTEXT" get nodes

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress \
  --create-namespace \
  --values values/ingress-nginx-values.yaml \
  --wait \
  --timeout 15m

helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --values values/vault-values.yaml \
  --set 'server.dev.devRootToken=root' \
  --wait \
  --timeout 15m

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values/kube-prometheus-stack-values.yaml \
  --dependency-update \
  --wait \
  --timeout 15m

helm upgrade --install loki grafana-community/loki \
  --namespace logging \
  --create-namespace \
  --values values/loki-values.yaml \
  --dependency-update \
  --wait \
  --timeout 15m

helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --create-namespace \
  --values values/grafana-values.yaml \
  --set 'adminPassword=admin' \
  --wait \
  --timeout 15m

kubectl --context "$CONTEXT" get pods --all-namespaces

