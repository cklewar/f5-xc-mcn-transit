output "mcn" {
  value = {
<<<<<<< HEAD
    aws   = module.aws.f5xc_aws_tgw
    gcp   = module.gcp.gcp_vpc
    azure = module.azure.vnet
    #firewall = volterra_active_network_policies.active

=======
    aws = module.aws.f5xc_aws_tgw
    gcp = module.gcp.gcp_vpc
    # azure    = module.azure.vnet
    firewall = volterra_active_network_policies.active
    # gcp = module.gcp.gcp_vpc["f5xc_instance_names"]
>>>>>>> 0.11.23
  }
}