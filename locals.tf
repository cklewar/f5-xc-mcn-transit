locals {
  template_input_dir_path  = abspath("./modules/aws/ec2/templates/")
  template_output_dir_path = abspath("./modules/aws/ec2/_out/")
  script_client_content    = templatefile("./templates/client.tftpl", {
    "server_ip" = module.azure_virtual_machine_spoke_b.virtual_machine["private_ip"]
  })
  script_server_content = templatefile("./templates/server.tftpl", {})

  custom_tags = {
    Owner                  = var.owner_tag
    f5xc-tenant            = var.f5xc_tenant
    f5xc-feature           = "f5xc-mcn-transit"
    f5xc-ves-io-creator-id = var.owner_tag
  }
}