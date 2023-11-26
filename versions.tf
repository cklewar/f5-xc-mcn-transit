terraform {
  required_version = ">= 1.3.0"
  cloud {
    organization = "cklewar"
    hostname     = "app.terraform.io"

    workspaces {
      name = "f5-xc-mcn-transit-module"
    }
  }
  
  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      version = "= 0.11.24"
    }
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.51.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.25.0"
    }
    google = {
      source = "hashicorp/google"
      version = ">= 4.48.0"
    }
    local = ">= 2.2.3"
    null = ">= 3.1.1"
  }
}