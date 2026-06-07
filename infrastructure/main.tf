locals {
  node_image = (
    var.kubernetes_node_image == null || trimspace(var.kubernetes_node_image) == ""
    ? null
    : trimspace(var.kubernetes_node_image)
  )

  kind_config_path = "${path.module}/${var.kind_config_filename}"

  kubeconfig_path_clean = var.kubeconfig_path == null ? "" : trimspace(var.kubeconfig_path)

  kubeconfig_path_effective = local.kubeconfig_path_clean == "" ? pathexpand("~/.kube/config") : pathexpand(local.kubeconfig_path_clean)

  kubeconfig_context = "kind-${var.cluster_name}"

  port_mapping_yaml_lines = flatten([
    for mapping in var.port_mappings : [
      "  - containerPort: ${mapping.container_port}",
      "    hostPort: ${mapping.host_port}",
      "    listenAddress: \"${mapping.listen_address}\"",
      "    protocol: ${upper(mapping.protocol)}",
    ]
  ])

  worker_node_yaml_lines = flatten([
    for _ in range(var.worker_node_count) : concat(
      ["- role: worker"],
      local.node_image == null ? [] : ["  image: ${local.node_image}"]
    )
  ])

  kind_config_yaml_lines = concat(
    [
      "kind: Cluster",
      "apiVersion: kind.x-k8s.io/v1alpha4",
      "kubeadmConfigPatches:",
      "- |",
      "  kind: ClusterConfiguration",
      "  apiServer:",
      "    extraArgs:",
      "      service-node-port-range: \"1-65535\"",
      "nodes:",
      "- role: control-plane",
    ],
    local.node_image == null ? [] : ["  image: ${local.node_image}"],
    ["  extraPortMappings:"],
    local.port_mapping_yaml_lines,
    local.worker_node_yaml_lines
  )

  kind_config_yaml = "${join("\n", local.kind_config_yaml_lines)}\n"

  kubeconfig_trigger_value = local.kubeconfig_path_clean == "" ? "__default__" : local.kubeconfig_path_clean

  host_ports_by_container_port = {
    for mapping in var.port_mappings : tostring(mapping.container_port) => mapping.host_port
  }

  platform_host_ports = {
    ingress_http  = lookup(local.host_ports_by_container_port, tostring(var.platform_node_ports.ingress_http), var.platform_node_ports.ingress_http)
    ingress_https = lookup(local.host_ports_by_container_port, tostring(var.platform_node_ports.ingress_https), var.platform_node_ports.ingress_https)
    vault         = lookup(local.host_ports_by_container_port, tostring(var.platform_node_ports.vault), var.platform_node_ports.vault)
    grafana       = lookup(local.host_ports_by_container_port, tostring(var.platform_node_ports.grafana), var.platform_node_ports.grafana)
    prometheus    = lookup(local.host_ports_by_container_port, tostring(var.platform_node_ports.prometheus), var.platform_node_ports.prometheus)
    loki          = lookup(local.host_ports_by_container_port, tostring(var.platform_node_ports.loki), var.platform_node_ports.loki)
  }

  app_image_ref = "${var.app_image_name}:${var.app_image_tag}"

  app_source_files = sort(distinct(concat(
    tolist(fileset("${path.module}/..", "Dockerfile")),
    tolist(fileset("${path.module}/..", "requirements.txt")),
    tolist(fileset("${path.module}/..", "config.py")),
    tolist(fileset("${path.module}/..", "backend/*.py")),
    tolist(fileset("${path.module}/..", "frontend/*.py")),
    tolist(fileset("${path.module}/..", "frontend/static/*")),
    tolist(fileset("${path.module}/..", "frontend/templates/*"))
  )))

  app_source_hash = sha256(join("", [
    for file in local.app_source_files : filesha256("${path.module}/../${file}")
  ]))
}
