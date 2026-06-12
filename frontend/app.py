import os
import sys
import requests
from flask import Flask, jsonify, render_template, request

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config import FRONTEND_HOST, FRONTEND_PORT, GRAFANA_URL, PROMETHEUS_URL, VAULT_UI_URL

app = Flask(__name__)

BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:5001")


@app.route("/")
def dashboard():
    try:
        health = requests.get(f"{BACKEND_URL}/api/health", timeout=5).json()
    except Exception:
        health = {"status": "unreachable", "service": "backend"}

    try:
        metrics = requests.get(f"{BACKEND_URL}/api/metrics", timeout=5).json()
    except Exception:
        metrics = {"cpu_usage": 0, "memory_usage": 0, "disk_usage": 0, "uptime_seconds": 0}

    return render_template(
        "dashboard.html",
        health=health,
        metrics=metrics,
        prometheus_url=PROMETHEUS_URL,
        grafana_url=GRAFANA_URL,
        vault_url=VAULT_UI_URL,
    )


@app.route("/api/simulate/success", methods=["POST"])
def proxy_success():
    resp = requests.get(f"{BACKEND_URL}/api/simulate/success", timeout=5)
    return resp.json(), resp.status_code


@app.route("/api/simulate/not_found", methods=["POST"])
def proxy_not_found():
    resp = requests.get(f"{BACKEND_URL}/api/simulate/not_found", timeout=5)
    return resp.json(), resp.status_code


@app.route("/api/simulate/error", methods=["POST"])
def proxy_error():
    resp = requests.get(f"{BACKEND_URL}/api/simulate/error", timeout=5)
    return resp.json(), resp.status_code


@app.route("/api/vault/validate", methods=["POST"])
def proxy_vault_validate():
    resp = requests.post(
        f"{BACKEND_URL}/api/vault/validate",
        json=request.get_json(silent=True) or {},
        timeout=8,
    )
    return jsonify(resp.json()), resp.status_code


@app.route("/api/logs/dummy", methods=["POST"])
def proxy_dummy_logs():
    resp = requests.post(
        f"{BACKEND_URL}/api/logs/dummy",
        json=request.get_json(silent=True) or {},
        timeout=8,
    )
    return jsonify(resp.json()), resp.status_code


if __name__ == "__main__":
    app.run(host=FRONTEND_HOST, port=FRONTEND_PORT, debug=True)
