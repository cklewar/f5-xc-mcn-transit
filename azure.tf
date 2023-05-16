provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
  alias        = "default"
}

provider "azurerm" {
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  alias = "eastus"
}

module "f5xc_azure_marketplace_agreement_hub_multi_nic" {
  source                = "./modules/azure/agreement"
  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  azure_tenant_id       = var.azure_tenant_id
  azure_subscription_id = var.azure_subscription_id
  f5xc_azure_ce_gw_type = "multi_nic"
}

module "azure_resource_group" {
  source                    = "./modules/azure/resource_group"
  azure_region              = var.azure_region
  azure_resource_group_name = format("%s-azure-hub-spoke-peer-rg-%s", var.project_prefix, var.project_suffix)
  providers                 = {
    azurerm = azurerm.eastus
  }
}

module "azure_vnet_spoke_a" {
  source                         = "./modules/azure/virtual_network"
  azure_region                   = var.azure_region
  azure_vnet_name                = format("%s-vnet-spoke-a-%s", var.project_prefix, var.project_suffix)
  azure_vnet_primary_ipv4        = "172.16.0.0/21"
  azure_vnet_resource_group_name = module.azure_resource_group.resource_group["name"]
  providers                      = {
    azurerm = azurerm.eastus
  }
}

module "azure_vnet_spoke_b" {
  source                         = "./modules/azure/virtual_network"
  azure_region                   = var.azure_region
  azure_vnet_name                = format("%s-vnet-spoke-b-%s", var.project_prefix, var.project_suffix)
  azure_vnet_primary_ipv4        = "172.16.8.0/21"
  azure_vnet_resource_group_name = module.azure_resource_group.resource_group["name"]
  providers                      = {
    azurerm = azurerm.eastus
  }
}

module "azure_subnet_spoke_a" {
  source                           = "./modules/azure/subnet"
  azure_subnet_address_prefixes    = ["172.16.0.0/24"]
  azure_subnet_name                = format("%s-azure-snet-spoke-a-%s", var.project_prefix, var.project_suffix)
  azure_subnet_resource_group_name = module.azure_resource_group.resource_group["name"]
  azure_vnet_name                  = module.azure_vnet_spoke_a.vnet["name"]
  providers                        = {
    azurerm = azurerm.eastus
  }
}

module "azure_subnet_spoke_a_outside" {
  source                           = "./modules/azure/subnet"
  azure_subnet_address_prefixes    = ["172.16.2.0/24"]
  azure_subnet_name                = format("%s-azure-snet-spoke-jh-a-%s", var.project_prefix, var.project_suffix)
  azure_subnet_resource_group_name = module.azure_resource_group.resource_group["name"]
  azure_vnet_name                  = module.azure_vnet_spoke_a.vnet["name"]
  providers                        = {
    azurerm = azurerm.eastus
  }
}

module "azure_subnet_spoke_b" {
  source                           = "./modules/azure/subnet"
  azure_subnet_address_prefixes    = ["172.16.8.0/24"]
  azure_subnet_name                = format("%s-azure-snet-spoke-b-%s", var.project_prefix, var.project_suffix)
  azure_subnet_resource_group_name = module.azure_resource_group.resource_group["name"]
  azure_vnet_name                  = module.azure_vnet_spoke_b.vnet["name"]
  providers                        = {
    azurerm = azurerm.eastus
  }
}

module "azure_subnet_spoke_b_outside" {
  source                           = "./modules/azure/subnet"
  azure_subnet_address_prefixes    = ["172.16.9.0/24"]
  azure_subnet_name                = format("%s-azure-snet-spoke-jh-b-%s", var.project_prefix, var.project_suffix)
  azure_subnet_resource_group_name = module.azure_resource_group.resource_group["name"]
  azure_vnet_name                  = module.azure_vnet_spoke_b.vnet["name"]
  providers                        = {
    azurerm = azurerm.eastus
  }
}

module "azure_virtual_machine_spoke_a" {
  source                     = "./modules/azure/linux_virtual_machine"
  azure_zone                 = element(var.azure_zones, 0)
  azure_zones                = var.azure_zones
  azure_region               = var.azure_region
  azure_resource_group_name  = module.azure_resource_group.resource_group["name"]
  azure_virtual_machine_name = format("%s-azure-vm-spoke-a-%s", var.project_prefix, var.project_suffix)
  azure_network_interfaces   = [
    {
      name             = format("%s-azure-vm-interface-spoke-a-outside-%s", var.project_prefix, var.project_suffix)
      tags             = { "tagA" : "tagValueA" }
      ip_configuration = {
        subnet_id                     = module.azure_subnet_spoke_a_outside.subnet["id"]
        create_public_ip_address      = true
        private_ip_address_allocation = "Dynamic"
      }
    }
  ]
  azure_linux_virtual_machine_custom_data = base64encode(local.script_client_content)
  ssh_public_key                          = file(var.ssh_public_key_file)
  custom_tags                             = local.custom_tags
  providers                               = {
    azurerm = azurerm.eastus
  }
}

module "azure_virtual_machine_spoke_b" {
  source                     = "./modules/azure/linux_virtual_machine"
  azure_zone                 = element(var.azure_zones, 0)
  azure_zones                = var.azure_zones
  azure_region               = var.azure_region
  azure_resource_group_name  = module.azure_resource_group.resource_group["name"]
  azure_virtual_machine_name = format("%s-azure-vm-spoke-b-%s", var.project_prefix, var.project_suffix)
  azure_network_interfaces   = [
    {
      name             = format("%s-azure-vm-interface-spoke-b-outside-%s", var.project_prefix, var.project_suffix)
      tags             = { "tagA" : "tagValueA" }
      ip_configuration = {
        subnet_id                     = module.azure_subnet_spoke_b_outside.subnet["id"]
        create_public_ip_address      = true
        private_ip_address_allocation = "Dynamic"
      }
    }
  ]
  azure_linux_virtual_machine_custom_data = base64encode(local.script_server_content)
  ssh_public_key                          = file(var.ssh_public_key_file)
  custom_tags                             = local.custom_tags
  providers                               = {
    azurerm = azurerm.eastus
  }
}

module "azure_security_group_spoke_a" {
  source                       = "./modules/azure/security_group"
  azure_region                 = var.azure_region
  azure_resource_group_name    = module.azure_resource_group.resource_group["name"]
  azure_security_group_name    = format("%s-spoke-a-sg-%s", var.project_prefix, var.project_suffix)
  azurerm_network_interface_id = element(module.azure_virtual_machine_spoke_a.virtual_machine["network_interface_ids"], 0)
  azure_linux_security_rules   = [
    {
      name                       = "SSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "IPERF_SERVER"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = module.azure_virtual_machine_spoke_b.virtual_machine["private_ip"]
      destination_address_prefix = module.azure_virtual_machine_spoke_a.virtual_machine["private_ip"]
    },
    {
      name                       = "OUTBOUND_ALL"
      priority                   = 1003
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  custom_tags = local.custom_tags
  providers   = {
    azurerm = azurerm.eastus
  }
}

module "azure_security_group_spoke_b" {
  source                       = "./modules/azure/security_group"
  azure_region                 = var.azure_region
  azure_resource_group_name    = module.azure_resource_group.resource_group["name"]
  azure_security_group_name    = format("%s-spoke-b-sg-%s", var.project_prefix, var.project_suffix)
  azurerm_network_interface_id = element(module.azure_virtual_machine_spoke_b.virtual_machine["network_interface_ids"], 0)
  azure_linux_security_rules   = [
    {
      name                       = "SSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "IPERF_SERVER"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = module.azure_virtual_machine_spoke_a.virtual_machine["private_ip"]
      destination_address_prefix = module.azure_virtual_machine_spoke_b.virtual_machine["private_ip"]
    },
    {
      name                       = "OUTBOUND_ALL"
      priority                   = 1003
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  custom_tags = local.custom_tags
  providers   = {
    azurerm = azurerm.eastus
  }
}

output "azure_virtual_machine_spokes" {
  value = {
    "spoke_a" = {
      "private_ip" = module.azure_virtual_machine_spoke_a.virtual_machine["private_ip"]
      "public_ip"  = module.azure_virtual_machine_spoke_a.virtual_machine["public_ip"]
    }
    "spoke_b" = {
      "private_ip" = module.azure_virtual_machine_spoke_b.virtual_machine["private_ip"]
      "public_ip"  = module.azure_virtual_machine_spoke_b.virtual_machine["public_ip"]
    }
  }
}

output "script_client_server_content" {
  value = {
    "client" = local.script_client_content
    "server" = local.script_server_content
  }
}

module "azure" {
  # depends_on                          = [module.f5xc_azure_marketplace_agreement_hub_multi_nic]
  source                              = "./modules/f5xc/site/azure"
  f5xc_api_url                        = var.f5xc_api_url
  f5xc_api_token                      = var.f5xc_api_token
  f5xc_namespace                      = var.f5xc_namespace
  f5xc_tenant                         = var.f5xc_tenant
  f5xc_azure_cred                     = var.f5xc_azure_cred
  f5xc_azure_region                   = var.azure_region
  f5xc_azure_site_name                = format("%s-hub-%s", var.project_prefix, var.project_suffix)
  f5xc_azure_vnet_site_resource_group = format("%s-hub-rg-%s", var.project_prefix, var.project_suffix)
  f5xc_azure_vnet_primary_ipv4        = "172.16.32.0/21"
  f5xc_azure_ce_gw_type               = "multi_nic"
  f5xc_azure_az_nodes                 = {
    node0 : {
      f5xc_azure_az                  = "1", f5xc_azure_vnet_inside_subnet = "172.16.32.0/24",
      f5xc_azure_vnet_outside_subnet = "172.16.33.0/24"
    }
    node1 : {
      f5xc_azure_az                  = "1", f5xc_azure_vnet_inside_subnet = "172.16.34.0/24",
      f5xc_azure_vnet_outside_subnet = "172.16.35.0/24"
    }
    node2 : {
      f5xc_azure_az                  = "1", f5xc_azure_vnet_inside_subnet = "172.16.36.0/24",
      f5xc_azure_vnet_outside_subnet = "172.16.37.0/24"
    }
  }
  f5xc_azure_hub_spoke_vnets = [
    {
      resource_group = module.azure_vnet_spoke_a.vnet["resource_group_name"]
      vnet_name      = module.azure_vnet_spoke_a.vnet.name
      auto           = true
      manual         = false
      labels         = {
        "app" = "reviews"
      }
    },
    {
      resource_group = module.azure_vnet_spoke_b.vnet["resource_group_name"]
      vnet_name      = module.azure_vnet_spoke_b.vnet.name
      auto           = true
      manual         = false
      labels         = {
        "app" = "reviews"
      }
    }
  ]
  f5xc_azure_vnet_static_routes = [
    {
      name             = format("%s-user-ip-spoke-a-%s", var.project_prefix, var.project_suffix)
      address_prefix   = format("%s/32", data.http.host_ip.response_body)
      route_table_name = format("rt-%s-vnet-spoke-a-%s", var.project_prefix, var.project_suffix)
      next_hop_type    = "Internet"
    },
    {
      name             = format("%s-user-ip-spoke-b-%s", var.project_prefix, var.project_suffix)
      address_prefix   = format("%s/32", data.http.host_ip.response_body)
      route_table_name = format("rt-%s-vnet-spoke-b-%s", var.project_prefix, var.project_suffix)
      next_hop_type    = "Internet"
    }
  ]
  f5xc_active_forward_proxy_policies = [
    {
      name      = format("%s-forward-all-%s", var.project_prefix, var.project_suffix)
      tenant    = var.f5xc_tenant
      namespace = var.f5xc_namespace
    }
  ]
  f5xc_active_network_policies = [
    {
      name      = format("%s-allow-all-%s", var.project_prefix, var.project_suffix)
      tenant    = var.f5xc_tenant
      namespace = var.f5xc_namespace
    }
  ]
  f5xc_azure_default_blocked_services = false
  f5xc_azure_default_ce_sw_version    = true
  f5xc_azure_default_ce_os_version    = true
  f5xc_azure_no_worker_nodes          = true
  ssh_public_key                      = file(var.ssh_public_key_file)
  custom_tags                         = local.custom_tags
  providers                           = {
    volterra = volterra.default
    azurerm  = azurerm.eastus
  }
}