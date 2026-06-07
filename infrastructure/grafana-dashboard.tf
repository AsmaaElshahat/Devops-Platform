locals {
  backend_dashboard_json = jsonencode({
    uid           = "backend-observability"
    title         = "Backend Observability"
    tags          = ["terraform", "backend", "loki", "prometheus"]
    timezone      = "browser"
    schemaVersion = 39
    version       = 1
    refresh       = "10s"
    time = {
      from = "now-30m"
      to   = "now"
    }
    templating = {
      list = []
    }
    panels = [
      {
        id          = 1
        type        = "stat"
        title       = "Backend Health"
        datasource  = { type = "prometheus", uid = "prometheus" }
        gridPos     = { h = 5, w = 6, x = 0, y = 0 }
        fieldConfig = { defaults = { unit = "none", min = 0, max = 1 }, overrides = [] }
        options     = { reduceOptions = { calcs = ["lastNotNull"], fields = "", values = false } }
        targets = [
          {
            refId = "A"
            expr  = "max(app_health_status)"
          }
        ]
      },
      {
        id          = 2
        type        = "timeseries"
        title       = "CPU, Memory, Disk"
        datasource  = { type = "prometheus", uid = "prometheus" }
        gridPos     = { h = 8, w = 18, x = 6, y = 0 }
        fieldConfig = { defaults = { unit = "percent", min = 0, max = 100 }, overrides = [] }
        targets = [
          { refId = "A", expr = "app_cpu_usage_percent", legendFormat = "CPU" },
          { refId = "B", expr = "app_memory_usage_percent", legendFormat = "Memory" },
          { refId = "C", expr = "app_disk_usage_percent", legendFormat = "Disk" }
        ]
      },
      {
        id          = 3
        type        = "timeseries"
        title       = "Backend Request Rate"
        datasource  = { type = "prometheus", uid = "prometheus" }
        gridPos     = { h = 7, w = 12, x = 0, y = 8 }
        fieldConfig = { defaults = { unit = "reqps" }, overrides = [] }
        targets = [
          {
            refId        = "A"
            expr         = "sum by (endpoint, status) (rate(app_http_requests_total[5m]))"
            legendFormat = "{{endpoint}} {{status}}"
          }
        ]
      },
      {
        id          = 4
        type        = "timeseries"
        title       = "Vault Validation Attempts"
        datasource  = { type = "prometheus", uid = "prometheus" }
        gridPos     = { h = 7, w = 12, x = 12, y = 8 }
        fieldConfig = { defaults = { unit = "ops" }, overrides = [] }
        targets = [
          {
            refId        = "A"
            expr         = "sum by (result) (rate(app_vault_validation_total[5m]))"
            legendFormat = "{{result}}"
          }
        ]
      },
      {
        id          = 5
        type        = "timeseries"
        title       = "Dummy Log Events"
        datasource  = { type = "prometheus", uid = "prometheus" }
        gridPos     = { h = 7, w = 8, x = 0, y = 15 }
        fieldConfig = { defaults = { unit = "ops" }, overrides = [] }
        targets = [
          {
            refId        = "A"
            expr         = "sum by (level) (rate(app_dummy_logs_total[5m]))"
            legendFormat = "{{level}}"
          }
        ]
      },
      {
        id         = 6
        type       = "logs"
        title      = "Backend Logs From Loki"
        datasource = { type = "loki", uid = "loki" }
        gridPos    = { h = 10, w = 16, x = 8, y = 15 }
        options    = { showLabels = true, showTime = true, wrapLogMessage = true }
        targets = [
          {
            refId = "A"
            expr  = "{namespace=\"${var.app_namespace}\", container=\"backend\"}"
          }
        ]
      }
    ]
  })
}
