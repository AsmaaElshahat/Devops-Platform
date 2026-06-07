output "cluster_name" {
  description = "Name of the Kind cluster managed by Terraform."
  value       = var.cluster_name
}

output "kubeconfig_context" {
  description = "kubectl context name created by Kind."
  value       = local.kubeconfig_context
}

output "kind_config_path" {
  description = "Path to the generated Kind cluster config."
  value       = local_file.kind_config.filename
}

output "host_port_mappings" {
  description = "Host ports exposed by the Kind control-plane node."
  value = {
    for mapping in var.port_mappings :
    mapping.host_port => {
      container_port = mapping.container_port
      listen_address = mapping.listen_address
      protocol       = upper(mapping.protocol)
    }
  }
}

output "platform_urls" {
  description = "Local URLs for platform services after terraform apply completes."
  value = {
    ingress_http  = "http://localhost:${local.platform_host_ports.ingress_http}"
    ingress_https = "https://localhost:${local.platform_host_ports.ingress_https}"
    vault         = "http://localhost:${local.platform_host_ports.vault}"
    grafana       = "http://localhost:${local.platform_host_ports.grafana}"
    prometheus    = "http://localhost:${local.platform_host_ports.prometheus}"
    loki          = "http://localhost:${local.platform_host_ports.loki}"
  }
}

output "app_urls" {
  description = "Local URLs for the Flask application."
  value = var.enable_app_deployment ? {
    ingress_url       = "http://${var.app_ingress_host}:${local.platform_host_ports.ingress_http}"
    localhost_command = "curl -H 'Host: ${var.app_ingress_host}' http://localhost:${local.platform_host_ports.ingress_http}/"
    hosts_file_hint   = "Add '127.0.0.1 ${var.app_ingress_host}' to your hosts file for browser access."
  } : {}
}

output "helm_releases" {
  description = "Phase 3 Helm releases managed by Terraform."
  value = var.enable_platform_helm_releases ? {
    ingress_nginx = {
      name      = "ingress-nginx"
      namespace = var.ingress_namespace
    }
    vault = {
      name      = "vault"
      namespace = var.vault_namespace
    }
    prometheus = {
      name      = "prometheus"
      namespace = var.monitoring_namespace
    }
    grafana = {
      name      = "grafana"
      namespace = var.monitoring_namespace
    }
    loki = {
      name      = "loki"
      namespace = var.logging_namespace
    }
    promtail = {
      name      = "promtail"
      namespace = var.logging_namespace
    }
  } : {}
}

output "next_commands" {
  description = "Useful commands after terraform apply completes."
  value = [
    "kubectl cluster-info --context ${local.kubeconfig_context}",
    "kubectl get nodes --context ${local.kubeconfig_context}",
    "kubectl get pods --all-namespaces --context ${local.kubeconfig_context}",
    "kubectl get pods -n ${var.app_namespace} --context ${local.kubeconfig_context}",
    "kind delete cluster --name ${var.cluster_name}"
  ]
}
