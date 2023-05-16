output "mcn" {
  value = {
    aws      = module.aws.f5xc_aws_tgw
    gco      = module.gcp.gcp_vpc
    azure    = module.azure.vnet
    firewall = volterra_active_network_policies.active
  }
}