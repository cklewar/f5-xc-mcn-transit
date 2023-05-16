variable "f5xc_azure_region" {
  type    = string
  default = "eastus"
}

variable "f5xc_azure_cred" {
  type    = string
  default = "sun-az-creds"
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "provisioner_connection_type" {
  type    = string
  default = "ssh"
}

variable "azure_zones" {
  type    = list(number)
  default = [1]
}

data "http" "host_ip" {
  url = "http://ifconfig.me"
}