terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "docker" {}
provider "local" {}
provider "null" {}

provider "kubernetes" {
  config_path    = local.kubeconfig_path_effective
  config_context = local.kubeconfig_context
}

provider "helm" {
  kubernetes {
    config_path    = local.kubeconfig_path_effective
    config_context = local.kubeconfig_context
  }
}
