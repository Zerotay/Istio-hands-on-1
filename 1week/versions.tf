terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.17.0"
      # Currently v3 has an issue about deploying library chart in desired namespace
      # version = "3.0.0-pre2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    # For applying multiple manifests in a yaml
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
  }

  # This block will be used in helm provider 3.0.0.
  # kubernetes = {
  #   config_path    = "~/.kube/config"
  # }
}
provider "kubernetes" {
  config_path    = "~/.kube/config"
}
provider "kubectl" {
  load_config_file = true
  config_path    = "~/.kube/config"
}
