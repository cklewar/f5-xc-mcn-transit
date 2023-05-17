provider "aws" {
  alias  = "default"
  region = var.aws_region
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
  alias        = "default"
}

provider "azurerm" {
  /*client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id*/
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  alias = "eastus"
}

provider "google" {
  region  = var.gcp_region
  alias   = "us-east1"
  project = var.gcp_project_id
}