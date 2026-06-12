import os

# App settings
FLASK_ENV = os.getenv("FLASK_ENV", "development")
DEBUG = FLASK_ENV == "development"

# Backend
BACKEND_HOST = os.getenv("BACKEND_HOST", "0.0.0.0")
BACKEND_PORT = int(os.getenv("BACKEND_PORT", "5001"))

# Frontend
FRONTEND_HOST = os.getenv("FRONTEND_HOST", "0.0.0.0")
FRONTEND_PORT = int(os.getenv("FRONTEND_PORT", "5000"))

# Vault
VAULT_ADDR = os.getenv("VAULT_ADDR", "http://localhost:8200")
VAULT_TOKEN = os.getenv("VAULT_TOKEN", "")

# Consul
CONSUL_ADDR = os.getenv("CONSUL_ADDR", "http://localhost:8500")

# Prometheus metrics port
METRICS_PORT = int(os.getenv("METRICS_PORT", "9090"))

# Browser-facing tool URLs
PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://localhost:9090")
GRAFANA_URL = os.getenv("GRAFANA_URL", "http://localhost:3000")
VAULT_UI_URL = os.getenv("VAULT_UI_URL", VAULT_ADDR)
