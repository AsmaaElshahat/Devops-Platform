resource "helm_release" "ingress_nginx" {
  count = var.enable_platform_helm_releases ? 1 : 0

  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.ingress_nginx_chart_version
  namespace        = var.ingress_namespace
  create_namespace = true

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = var.helm_timeout_seconds

  values = [
    yamlencode({
      controller = {
        service = {
          type = "NodePort"
          nodePorts = {
            http  = var.platform_node_ports.ingress_http
            https = var.platform_node_ports.ingress_https
          }
        }
      }
    })
  ]

  depends_on = [null_resource.kind_cluster]
}

resource "helm_release" "vault" {
  count = var.enable_platform_helm_releases ? 1 : 0

  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = var.vault_chart_version
  namespace        = var.vault_namespace
  create_namespace = true

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = var.helm_timeout_seconds

  values = [
    yamlencode({
      injector = {
        enabled = true
      }
      server = {
        dev = {
          enabled = true
        }
        dataStorage = {
          enabled = false
        }
        auditStorage = {
          enabled = false
        }
        service = {
          type     = "NodePort"
          nodePort = var.platform_node_ports.vault
        }
      }
      ui = {
        enabled     = true
        serviceType = "ClusterIP"
      }
    })
  ]

  set_sensitive {
    name  = "server.dev.devRootToken"
    value = var.vault_dev_root_token
  }

  depends_on = [null_resource.kind_cluster]
}

resource "helm_release" "prometheus" {
  count = var.enable_platform_helm_releases ? 1 : 0

  name              = "prometheus"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "kube-prometheus-stack"
  version           = var.prometheus_stack_chart_version
  namespace         = var.monitoring_namespace
  create_namespace  = true
  dependency_update = true

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = var.helm_timeout_seconds

  values = [
    yamlencode({
      grafana = {
        enabled = false
      }
      prometheus = {
        service = {
          type     = "NodePort"
          nodePort = var.platform_node_ports.prometheus
        }
        prometheusSpec = {
          retention                               = "7d"
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          ruleSelectorNilUsesHelmValues           = false
        }
        additionalServiceMonitors = var.enable_app_deployment ? [
          {
            name = "flask-backend"
            additionalLabels = {
              app       = "flask-app"
              component = "backend"
              managedBy = "terraform"
            }
            selector = {
              matchLabels = {
                app       = "flask-app"
                component = "backend"
              }
            }
            namespaceSelector = {
              matchNames = [var.app_namespace]
            }
            endpoints = [
              {
                port     = "http"
                path     = "/metrics"
                interval = "15s"
              }
            ]
          }
        ] : []
      }
    })
  ]

  depends_on = [null_resource.kind_cluster]
}

resource "helm_release" "loki" {
  count = var.enable_platform_helm_releases ? 1 : 0

  name              = "loki"
  repository        = "https://grafana-community.github.io/helm-charts"
  chart             = "loki"
  version           = var.loki_chart_version
  namespace         = var.logging_namespace
  create_namespace  = true
  dependency_update = true

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = var.helm_timeout_seconds

  values = [
    yamlencode({
      deploymentMode = "Monolithic"

      loki = {
        auth_enabled = false
        commonConfig = {
          replication_factor = 1
        }
        schemaConfig = {
          configs = [
            {
              from         = "2024-04-01"
              store        = "tsdb"
              object_store = "filesystem"
              schema       = "v13"
              index = {
                prefix = "loki_index_"
                period = "24h"
              }
            }
          ]
        }
        storage = {
          type = "filesystem"
        }
        limits_config = {
          allow_structured_metadata = true
          volume_enabled            = true
        }
        ruler = {
          enable_api = true
        }
      }

      minio = {
        enabled = false
      }

      singleBinary = {
        replicas = 1
        persistence = {
          enabled = false
        }
      }

      backend = {
        replicas = 0
      }
      read = {
        replicas = 0
      }
      write = {
        replicas = 0
      }
      ingester = {
        replicas = 0
      }
      querier = {
        replicas = 0
      }
      queryFrontend = {
        replicas = 0
      }
      queryScheduler = {
        replicas = 0
      }
      distributor = {
        replicas = 0
      }
      compactor = {
        replicas = 0
      }
      indexGateway = {
        replicas = 0
      }
      bloomPlanner = {
        replicas = 0
      }
      bloomBuilder = {
        replicas = 0
      }
      bloomGateway = {
        replicas = 0
      }

      gateway = {
        service = {
          type     = "NodePort"
          nodePort = var.platform_node_ports.loki
        }
      }
    })
  ]

  depends_on = [null_resource.kind_cluster]
}

resource "helm_release" "grafana" {
  count = var.enable_platform_helm_releases ? 1 : 0

  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.grafana_chart_version
  namespace        = var.monitoring_namespace
  create_namespace = true

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = var.helm_timeout_seconds

  values = [
    yamlencode({
      adminUser = var.grafana_admin_user
      service = {
        type     = "NodePort"
        nodePort = var.platform_node_ports.grafana
      }
      persistence = {
        enabled = false
      }
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              uid       = "prometheus"
              access    = "proxy"
              url       = "http://prometheus-kube-prometheus-prometheus.${var.monitoring_namespace}.svc.cluster.local:9090"
              isDefault = true
            },
            {
              name   = "Loki"
              type   = "loki"
              uid    = "loki"
              access = "proxy"
              url    = "http://loki-gateway.${var.logging_namespace}.svc.cluster.local"
            }
          ]
        }
      }
      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers = [
            {
              name            = "default"
              orgId           = 1
              folder          = ""
              type            = "file"
              disableDeletion = false
              editable        = true
              options = {
                path = "/var/lib/grafana/dashboards/default"
              }
            }
          ]
        }
      }
      dashboards = {
        default = {
          "backend-observability" = {
            json = local.backend_dashboard_json
          }
          "request-outcomes" = {
            json = local.request_outcomes_dashboard_json
          }
        }
      }
      sidecar = {
        dashboards = {
          enabled = true
        }
      }
    })
  ]

  set_sensitive {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [
    helm_release.prometheus,
    helm_release.loki,
    helm_release.promtail
  ]
}

resource "helm_release" "promtail" {
  count = var.enable_platform_helm_releases ? 1 : 0

  name             = "promtail"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "promtail"
  version          = var.promtail_chart_version
  namespace        = var.logging_namespace
  create_namespace = true

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = var.helm_timeout_seconds

  values = [
    yamlencode({
      config = {
        clients = [
          {
            url = "http://loki-gateway.${var.logging_namespace}.svc.cluster.local/loki/api/v1/push"
          }
        ]
        snippets = {
          scrapeConfigs = <<-EOT
            - job_name: ${var.app_namespace}-pod-logs
              pipeline_stages:
                - cri: {}
              static_configs:
                - targets:
                    - localhost
                  labels:
                    job: ${var.app_namespace}/pod-logs
                    namespace: ${var.app_namespace}
                    __path__: /var/log/pods/${var.app_namespace}_*/*/*.log
          EOT
        }
      }
      tolerations = []
    })
  ]

  depends_on = [
    helm_release.loki,
    null_resource.kind_node_sysctls
  ]
}
