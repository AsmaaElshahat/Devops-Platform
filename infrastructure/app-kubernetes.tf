resource "null_resource" "app_image" {
  count = var.enable_app_deployment ? 1 : 0

  triggers = {
    image_ref        = local.app_image_ref
    app_source_hash  = local.app_source_hash
    cluster_name     = var.cluster_name
    kind_config_hash = sha256(local_file.kind_config.content)
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/.."
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      docker build -t "${local.app_image_ref}" .
      kind load docker-image "${local.app_image_ref}" --name "${var.cluster_name}"
    EOT
  }

  depends_on = [null_resource.kind_cluster]
}

resource "kubernetes_namespace_v1" "app" {
  count = var.enable_app_deployment ? 1 : 0

  metadata {
    name = var.app_namespace
    labels = {
      app       = "flask-app"
      managedBy = "terraform"
    }
  }

  depends_on = [null_resource.kind_cluster]
}

resource "kubernetes_config_map_v1" "app" {
  count = var.enable_app_deployment ? 1 : 0

  metadata {
    name      = "flask-app-config"
    namespace = kubernetes_namespace_v1.app[0].metadata[0].name
    labels = {
      app       = "flask-app"
      managedBy = "terraform"
    }
  }

  data = {
    BACKEND_HOST      = "0.0.0.0"
    BACKEND_PORT      = "5001"
    FRONTEND_HOST     = "0.0.0.0"
    FRONTEND_PORT     = "5000"
    BACKEND_URL       = "http://backend.${var.app_namespace}.svc.cluster.local:5001"
    VAULT_ADDR        = "http://vault.${var.vault_namespace}.svc.cluster.local:8200"
    VAULT_SECRET_PATH = var.app_vault_secret_path
    FLASK_ENV         = "production"
  }
}

resource "kubernetes_secret_v1" "app_vault" {
  count = var.enable_app_deployment ? 1 : 0

  metadata {
    name      = "flask-app-vault"
    namespace = kubernetes_namespace_v1.app[0].metadata[0].name
    labels = {
      app       = "flask-app"
      managedBy = "terraform"
    }
  }

  data = {
    VAULT_TOKEN = var.vault_dev_root_token
  }

  type = "Opaque"
}

resource "kubernetes_deployment_v1" "backend" {
  count = var.enable_app_deployment ? 1 : 0

  metadata {
    name      = "backend"
    namespace = kubernetes_namespace_v1.app[0].metadata[0].name
    labels = {
      app       = "flask-app"
      component = "backend"
      managedBy = "terraform"
    }
  }

  spec {
    replicas = var.app_backend_replicas

    selector {
      match_labels = {
        app       = "flask-app"
        component = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app       = "flask-app"
          component = "backend"
        }
        annotations = {
          "app.kubernetes.io/source-hash" = local.app_source_hash
        }
      }

      spec {
        container {
          name              = "backend"
          image             = local.app_image_ref
          image_pull_policy = "IfNotPresent"
          command           = ["python", "backend/api.py"]

          port {
            name           = "http"
            container_port = 5001
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.app[0].metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.app_vault[0].metadata[0].name
            }
          }

          readiness_probe {
            http_get {
              path = "/api/health"
              port = "http"
            }

            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 6
          }

          liveness_probe {
            http_get {
              path = "/api/health"
              port = "http"
            }

            initial_delay_seconds = 20
            period_seconds        = 20
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [null_resource.app_image]
}

resource "kubernetes_service_v1" "backend" {
  count = var.enable_app_deployment ? 1 : 0

  metadata {
    name      = "backend"
    namespace = kubernetes_namespace_v1.app[0].metadata[0].name
    labels = {
      app       = "flask-app"
      component = "backend"
      managedBy = "terraform"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app       = "flask-app"
      component = "backend"
    }

    port {
      name        = "http"
      port        = 5001
      target_port = "http"
    }
  }
}

resource "kubernetes_deployment_v1" "frontend" {
  count = var.enable_app_deployment ? 1 : 0

  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace_v1.app[0].metadata[0].name
    labels = {
      app       = "flask-app"
      component = "frontend"
      managedBy = "terraform"
    }
  }

  spec {
    replicas = var.app_frontend_replicas

    selector {
      match_labels = {
        app       = "flask-app"
        component = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app       = "flask-app"
          component = "frontend"
        }
        annotations = {
          "app.kubernetes.io/source-hash" = local.app_source_hash
        }
      }

      spec {
        container {
          name              = "frontend"
          image             = local.app_image_ref
          image_pull_policy = "IfNotPresent"
          command           = ["python", "frontend/app.py"]

          port {
            name           = "http"
            container_port = 5000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.app[0].metadata[0].name
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }

            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 6
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }

            initial_delay_seconds = 20
            period_seconds        = 20
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [
    null_resource.app_image,
    kubernetes_service_v1.backend
  ]
}

resource "kubernetes_service_v1" "frontend" {
  count = var.enable_app_deployment ? 1 : 0

  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace_v1.app[0].metadata[0].name
    labels = {
      app       = "flask-app"
      component = "frontend"
      managedBy = "terraform"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app       = "flask-app"
      component = "frontend"
    }

    port {
      name        = "http"
      port        = 5000
      target_port = "http"
    }
  }
}

resource "kubernetes_ingress_v1" "app" {
  count = var.enable_app_deployment ? 1 : 0

  metadata {
    name      = "flask-app"
    namespace = kubernetes_namespace_v1.app[0].metadata[0].name
    labels = {
      app       = "flask-app"
      managedBy = "terraform"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = var.app_ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.frontend[0].metadata[0].name

              port {
                number = 5000
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.ingress_nginx]
}

resource "kubernetes_manifest" "backend_service_monitor" {
  count = var.enable_app_deployment && var.enable_platform_helm_releases ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "flask-backend"
      namespace = kubernetes_namespace_v1.app[0].metadata[0].name
      labels = {
        app       = "flask-app"
        component = "backend"
        release   = "prometheus"
        managedBy = "terraform"
      }
    }
    spec = {
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
  }

  depends_on = [
    helm_release.prometheus,
    kubernetes_service_v1.backend
  ]
}
