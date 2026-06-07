resource "local_file" "kind_config" {
  filename        = local.kind_config_path
  content         = local.kind_config_yaml
  file_permission = "0644"
}

resource "null_resource" "kind_cluster" {
  triggers = {
    cluster_name    = var.cluster_name
    kind_config_sha = sha256(local_file.kind_config.content)
    kubeconfig_path = local.kubeconfig_trigger_value
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KIND_KUBECONFIG_PATH = local.kubeconfig_path_clean
    }
    command = <<-EOT
      set -euo pipefail

      kubeconfig_args=()
      if [ -n "$KIND_KUBECONFIG_PATH" ]; then
        kubeconfig_args=(--kubeconfig "$KIND_KUBECONFIG_PATH")
      fi

      if ! command -v kind >/dev/null 2>&1; then
        echo "kind is required but was not found on PATH." >&2
        exit 1
      fi

      if ! command -v docker >/dev/null 2>&1; then
        echo "docker is required by kind but was not found on PATH." >&2
        echo "Enable Docker Desktop WSL integration for this distro, then rerun terraform apply." >&2
        exit 1
      fi

      if kind get clusters | grep -x "${var.cluster_name}" >/dev/null 2>&1; then
        echo "Kind cluster ${var.cluster_name} already exists; skipping create."
      else
        kind create cluster --name "${var.cluster_name}" --config "${local_file.kind_config.filename}" "$${kubeconfig_args[@]}"
      fi
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KIND_KUBECONFIG_PATH = self.triggers.kubeconfig_path
    }
    command = <<-EOT
      set -euo pipefail

      kubeconfig_args=()
      if [ "$KIND_KUBECONFIG_PATH" != "__default__" ]; then
        kubeconfig_args=(--kubeconfig "$KIND_KUBECONFIG_PATH")
      fi

      if ! command -v kind >/dev/null 2>&1; then
        echo "kind is not available; skipping Kind cluster deletion."
        exit 0
      fi

      if kind get clusters | grep -x "${self.triggers.cluster_name}" >/dev/null 2>&1; then
        kind delete cluster --name "${self.triggers.cluster_name}" "$${kubeconfig_args[@]}"
      else
        echo "Kind cluster ${self.triggers.cluster_name} is already absent."
      fi
    EOT
  }

  depends_on = [local_file.kind_config]
}
