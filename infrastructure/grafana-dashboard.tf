locals {
  backend_dashboard_json          = file("${path.module}/../monitoring/grafana/dashboards/backend-dashboard.json")
  request_outcomes_dashboard_json = file("${path.module}/../monitoring/grafana/dashboards/request-outcomes-dashboard.json")
}
