import os
import sys
import time
import random
import json
import logging
from flask import Flask, jsonify, make_response, request
import requests
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter, Gauge

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config import BACKEND_HOST, BACKEND_PORT

app = Flask(__name__)
logging.basicConfig(level=logging.INFO, format="%(message)s")

metrics = PrometheusMetrics(app)

# --- Custom Prometheus metrics ---

# Health status gauge: 1 = healthy, 0 = unhealthy
health_status = Gauge("app_health_status", "Application health status (1=healthy, 0=unhealthy)").set(1)

# Request counters per status code
http_requests_total = Counter(
    "app_http_requests_total",
    "Total HTTP requests by endpoint and status",
    ["endpoint", "status"]
)

vault_validation_total = Counter(
    "app_vault_validation_total",
    "Total Vault validation attempts by result",
    ["result"]
)

dummy_logs_total = Counter(
    "app_dummy_logs_total",
    "Total dummy backend log events by level",
    ["level"]
)

# Simulated system metrics gauge
cpu_usage = Gauge("app_cpu_usage_percent", "Simulated CPU usage percent")
memory_usage = Gauge("app_memory_usage_percent", "Simulated memory usage percent")
disk_usage = Gauge("app_disk_usage_percent", "Simulated disk usage percent")

start_time = time.time()
VAULT_ADDR = os.getenv("VAULT_ADDR", "http://localhost:8200").rstrip("/")
VAULT_TOKEN = os.getenv("VAULT_TOKEN", "")
VAULT_SECRET_PATH = os.getenv("VAULT_SECRET_PATH", "cubbyhole/asmaa").strip("/")


def emit_log(level, event, **fields):
    payload = {
        "service": "backend",
        "event": event,
        "level": level,
        "timestamp": time.time(),
        **fields,
    }
    message = json.dumps(payload, sort_keys=True)
    getattr(app.logger, level, app.logger.info)(message)


def update_system_metrics():
    """Periodically update simulated system metrics."""
    while True:
        cpu_usage.set(round(random.uniform(10, 85), 1))
        memory_usage.set(round(random.uniform(30, 90), 1))
        disk_usage.set(round(random.uniform(20, 60), 1))
        time.sleep(5)


threading = __import__("threading")
metrics_thread = threading.Thread(target=update_system_metrics, daemon=True)
metrics_thread.start()


# --- Helper to track request ---
def track_request(endpoint, status_code):
    http_requests_total.labels(endpoint=endpoint, status=str(status_code)).inc()


def read_vault_secret():
    if not VAULT_TOKEN:
        raise RuntimeError("VAULT_TOKEN is not configured")

    response = requests.get(
        f"{VAULT_ADDR}/v1/{VAULT_SECRET_PATH}",
        headers={"X-Vault-Token": VAULT_TOKEN},
        timeout=5,
    )
    response.raise_for_status()
    payload = response.json()
    return payload.get("data", {})


# --- Endpoints ---

@app.route("/api/health")
def health():
    track_request("health", 200)
    return jsonify({
        "status": "healthy",
        "service": "backend",
        "timestamp": time.time(),
        "uptime_seconds": round(time.time() - start_time, 1),
    })


@app.route("/api/metrics")
def get_metrics():
    track_request("metrics", 200)
    json_data = {
        "service": "backend",
        "cpu_usage": cpu_usage._value.get(),
        "memory_usage": memory_usage._value.get(),
        "disk_usage": disk_usage._value.get(),
        "uptime_seconds": int(round(time.time() - start_time, 1)),
        "timestamp": time.time(),
    }
    return jsonify(json_data)


@app.route("/api/vault/validate", methods=["POST"])
def validate_vault_value():
    payload = request.get_json(silent=True) or {}
    key = str(payload.get("key", "")).strip()
    expected_value = str(payload.get("value", "")).strip()

    if not key or not expected_value:
        track_request("vault_validate", 400)
        vault_validation_total.labels(result="bad_request").inc()
        return make_response(jsonify({
            "status": "bad_request",
            "message": "key and value are required",
        }), 400)

    try:
        secret_data = read_vault_secret()
    except Exception as exc:
        track_request("vault_validate", 502)
        vault_validation_total.labels(result="vault_error").inc()
        emit_log("error", "vault_validation_error", key=key, error=str(exc))
        return make_response(jsonify({
            "status": "vault_error",
            "message": "Could not read secret from Vault",
        }), 502)

    actual_value = secret_data.get(key)
    valid = str(actual_value) == expected_value
    result = "valid" if valid else "invalid"
    status_code = 200 if valid else 403

    track_request("vault_validate", status_code)
    vault_validation_total.labels(result=result).inc()
    emit_log("info", "vault_validation", key=key, result=result)

    return make_response(jsonify({
        "status": result,
        "valid": valid,
        "key": key,
        "path": VAULT_SECRET_PATH,
    }), status_code)


@app.route("/api/logs/dummy", methods=["POST"])
def generate_dummy_logs():
    payload = request.get_json(silent=True) or {}
    count = int(payload.get("count", 5))
    count = max(1, min(count, 25))

    levels = ["info", "warning", "error"]
    generated = []

    for index in range(count):
        level = levels[index % len(levels)]
        trace_id = f"trace-{int(time.time())}-{random.randint(1000, 9999)}"
        emit_log(
            level,
            "dummy_backend_log",
            trace_id=trace_id,
            sequence=index + 1,
            message=f"Generated {level} log for Loki demo",
        )
        dummy_logs_total.labels(level=level).inc()
        generated.append({"level": level, "trace_id": trace_id})

    track_request("dummy_logs", 200)
    return jsonify({
        "status": "generated",
        "count": count,
        "logs": generated,
    })


@app.route("/api/simulate/success")
def simulate_success():
    emit_log("info", "simulate_success", message="Success simulated")
    track_request("simulate_success", 200)
    return jsonify({
        "message": "Success simulated",
        "status": "ok",
        "timestamp": time.time(),
    })


@app.route("/api/simulate/not_found")
def simulate_not_found():
    emit_log("warning", "simulate_not_found", message="Not found simulated")
    track_request("simulate_not_found", 404)
    resp = make_response(jsonify({
        "message": "Not found simulated",
        "status": "not_found",
        "timestamp": time.time(),
    }), 404)
    return resp


@app.route("/api/simulate/error")
def simulate_error():
    emit_log("error", "simulate_error", message="Internal server error simulated")
    track_request("simulate_error", 500)
    resp = make_response(jsonify({
        "message": "Internal server error simulated",
        "status": "error",
        "timestamp": time.time(),
    }), 500)
    return resp


if __name__ == "__main__":
    app.run(host=BACKEND_HOST, port=BACKEND_PORT, debug=False)
