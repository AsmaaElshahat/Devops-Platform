#!/usr/bin/env bash
set -euo pipefail

CONTEXT="${CONTEXT:-kind-devops-platform}"

kubectl --context "$CONTEXT" get nodes -o wide
kubectl --context "$CONTEXT" get pods --all-namespaces
kubectl --context "$CONTEXT" get svc --all-namespaces

printf '\nLocal service smoke tests:\n'
curl -sS -o /dev/null -w 'ingress http:  %{http_code}\n' http://localhost:8080/ || true
curl -sS -o /dev/null -w 'grafana:       %{http_code}\n' http://localhost:3000/login || true
curl -sS -o /dev/null -w 'prometheus:    %{http_code}\n' http://localhost:9090/-/ready || true
curl -sS -o /dev/null -w 'vault:         %{http_code}\n' http://localhost:8200/v1/sys/health || true
curl -sS -o /dev/null -w 'loki:          %{http_code}\n' http://localhost:3100/loki/api/v1/status/buildinfo || true

