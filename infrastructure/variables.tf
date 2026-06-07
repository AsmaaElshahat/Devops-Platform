variable "cluster_name" {
  description = "Name of the local Kind cluster."
  type        = string
  default     = "devops-platform"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.cluster_name))
    error_message = "cluster_name must use lowercase letters, numbers, and hyphens, and must start and end with an alphanumeric character."
  }
}

variable "worker_node_count" {
  description = "Number of Kind worker nodes to add alongside the control-plane node."
  type        = number
  default     = 1

  validation {
    condition     = var.worker_node_count >= 0 && var.worker_node_count <= 5 && floor(var.worker_node_count) == var.worker_node_count
    error_message = "worker_node_count must be an integer between 0 and 5."
  }
}

variable "kubernetes_node_image" {
  description = "Optional Kind node image. Leave null to use the default image from the installed Kind version."
  type        = string
  default     = null
  nullable    = true
}

variable "kind_config_filename" {
  description = "File name for the generated Kind cluster config."
  type        = string
  default     = "kind-config.yaml"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.kind_config_filename))
    error_message = "kind_config_filename must be a simple file name containing only letters, numbers, dots, underscores, or hyphens."
  }
}

variable "kubeconfig_path" {
  description = "Optional kubeconfig path passed to kind create/delete. Leave null to use the default kubeconfig."
  type        = string
  default     = null
  nullable    = true
}

variable "port_mappings" {
  description = "Host-to-container port mappings exposed on the Kind control-plane node."
  type = list(object({
    container_port = number
    host_port      = number
    listen_address = optional(string, "127.0.0.1")
    protocol       = optional(string, "TCP")
  }))

  default = [
    {
      container_port = 80
      host_port      = 8080
    },
    {
      container_port = 443
      host_port      = 8443
    },
    {
      container_port = 8200
      host_port      = 8200
    },
    {
      container_port = 3000
      host_port      = 3000
    },
    {
      container_port = 9090
      host_port      = 9090
    },
    {
      container_port = 3100
      host_port      = 3100
    }
  ]

  validation {
    condition = alltrue([
      for mapping in var.port_mappings :
      mapping.container_port >= 1 &&
      mapping.container_port <= 65535 &&
      mapping.host_port >= 1 &&
      mapping.host_port <= 65535 &&
      contains(["TCP", "UDP", "SCTP"], upper(mapping.protocol))
    ])
    error_message = "Every port mapping must use valid container/host ports and a TCP, UDP, or SCTP protocol."
  }
}

variable "enable_platform_helm_releases" {
  description = "Whether Terraform should deploy the Phase 3 platform Helm charts after creating the Kind cluster."
  type        = bool
  default     = true
}

variable "helm_timeout_seconds" {
  description = "Timeout, in seconds, for each Helm release install or upgrade."
  type        = number
  default     = 900

  validation {
    condition     = var.helm_timeout_seconds >= 60 && var.helm_timeout_seconds <= 3600
    error_message = "helm_timeout_seconds must be between 60 and 3600."
  }
}

variable "platform_node_ports" {
  description = "NodePort values used by platform services inside the Kind control-plane container."
  type = object({
    ingress_http  = number
    ingress_https = number
    vault         = number
    grafana       = number
    prometheus    = number
    loki          = number
  })
  default = {
    ingress_http  = 80
    ingress_https = 443
    vault         = 8200
    grafana       = 3000
    prometheus    = 9090
    loki          = 3100
  }

  validation {
    condition = alltrue([
      for port in values(var.platform_node_ports) :
      port >= 1 && port <= 65535
    ])
    error_message = "Every platform node port must be between 1 and 65535."
  }
}

variable "ingress_namespace" {
  description = "Namespace for the ingress-nginx Helm release."
  type        = string
  default     = "ingress"
}

variable "vault_namespace" {
  description = "Namespace for the Vault Helm release."
  type        = string
  default     = "vault"
}

variable "monitoring_namespace" {
  description = "Namespace for Prometheus and Grafana Helm releases."
  type        = string
  default     = "monitoring"
}

variable "logging_namespace" {
  description = "Namespace for the Loki Helm release."
  type        = string
  default     = "logging"
}

variable "ingress_nginx_chart_version" {
  description = "Optional ingress-nginx chart version. Leave null to use the latest matching chart from the repository."
  type        = string
  default     = null
  nullable    = true
}

variable "vault_chart_version" {
  description = "Optional HashiCorp Vault chart version. Leave null to use the latest matching chart from the repository."
  type        = string
  default     = null
  nullable    = true
}

variable "prometheus_stack_chart_version" {
  description = "Optional kube-prometheus-stack chart version. Leave null to use the latest matching chart from the repository."
  type        = string
  default     = null
  nullable    = true
}

variable "grafana_chart_version" {
  description = "Optional Grafana chart version. Leave null to use the latest matching chart from the repository."
  type        = string
  default     = null
  nullable    = true
}

variable "loki_chart_version" {
  description = "Optional Loki chart version. Leave null to use the latest matching chart from the repository."
  type        = string
  default     = null
  nullable    = true
}

variable "promtail_chart_version" {
  description = "Optional Promtail chart version. Leave null to use the latest matching chart from the repository."
  type        = string
  default     = null
  nullable    = true
}

variable "grafana_admin_user" {
  description = "Admin username for Grafana."
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana."
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "vault_dev_root_token" {
  description = "Root token for the local Vault dev server."
  type        = string
  default     = "root"
  sensitive   = true
}

variable "enable_app_deployment" {
  description = "Whether Terraform should build/load and deploy the Flask application to Kubernetes."
  type        = bool
  default     = true
}

variable "app_namespace" {
  description = "Kubernetes namespace for the Flask application."
  type        = string
  default     = "devops-app"
}

variable "app_image_name" {
  description = "Local Docker image name for the Flask application."
  type        = string
  default     = "flask-app"
}

variable "app_image_tag" {
  description = "Local Docker image tag for the Flask application."
  type        = string
  default     = "latest"
}

variable "app_frontend_replicas" {
  description = "Number of frontend pods."
  type        = number
  default     = 2

  validation {
    condition     = var.app_frontend_replicas >= 1 && var.app_frontend_replicas <= 5 && floor(var.app_frontend_replicas) == var.app_frontend_replicas
    error_message = "app_frontend_replicas must be an integer between 1 and 5."
  }
}

variable "app_backend_replicas" {
  description = "Number of backend pods."
  type        = number
  default     = 2

  validation {
    condition     = var.app_backend_replicas >= 1 && var.app_backend_replicas <= 5 && floor(var.app_backend_replicas) == var.app_backend_replicas
    error_message = "app_backend_replicas must be an integer between 1 and 5."
  }
}

variable "app_ingress_host" {
  description = "Host name routed by ingress-nginx to the Flask frontend."
  type        = string
  default     = "app.local"
}

variable "app_vault_secret_path" {
  description = "Vault API secret path used by the backend validation endpoint."
  type        = string
  default     = "cubbyhole/asmaa"
}
