module "workload_vpc_a" {
  source             = "./modules/aws/vpc"
  aws_owner          = var.owner_tag
  aws_region         = var.aws_region
  aws_az_name        = format("%s%s", var.aws_region, "a")
  aws_vpc_name       = format("%s-%s-%s", var.project_prefix, var.aws_vpc_workload_a_name, var.project_suffix)
  aws_vpc_cidr_block = var.aws_vpc_workload_a_cidr_block
  create_igw         = true
  custom_tags        = local.custom_tags
  providers          = {
    aws = aws.default
  }
}

module "workload_vpc_b" {
  source             = "./modules/aws/vpc"
  aws_owner          = var.owner_tag
  aws_region         = var.aws_region
  aws_az_name        = format("%s%s", var.aws_region, "a")
  aws_vpc_name       = format("%s-%s-%s", var.project_prefix, var.aws_vpc_workload_b_name, var.project_suffix)
  aws_vpc_cidr_block = var.aws_vpc_workload_b_cidr_block
  create_igw         = true
  custom_tags        = local.custom_tags
  providers          = {
    aws = aws.default
  }
}

module "workload_subnets_a" {
  source          = "./modules/aws/subnet"
  aws_vpc_id      = module.workload_vpc_a.aws_vpc["id"]
  aws_vpc_subnets = [
    {
      name                    = format("%s-%s-%s-public", var.project_suffix, var.aws_vpc_workload_a_name, var.project_suffix)
      owner                   = var.owner_tag
      cidr_block              = var.aws_subnet_workload_a_public_cidr
      custom_tags             = local.custom_tags
      availability_zone       = format("%s%s", var.aws_region, "a")
      map_public_ip_on_launch = true
    },
    {
      name                    = format("%s-%s-%s-private", var.project_suffix, var.aws_vpc_workload_a_name, var.project_suffix)
      owner                   = var.owner_tag
      cidr_block              = var.aws_subnet_workload_a_private_cidr
      custom_tags             = local.custom_tags
      availability_zone       = format("%s%s", var.aws_region, "a")
      map_public_ip_on_launch = false
    }
  ]
  providers = {
    aws = aws.default
  }
}

module "workload_subnets_b" {
  source          = "./modules/aws/subnet"
  aws_vpc_id      = module.workload_vpc_b.aws_vpc["id"]
  aws_vpc_subnets = [
    {
      name                    = format("%s-%s-%s-public", var.project_suffix, var.aws_vpc_workload_b_name, var.project_suffix)
      owner                   = var.owner_tag
      cidr_block              = var.aws_subnet_workload_b_public_cidr
      custom_tags             = local.custom_tags
      availability_zone       = format("%s%s", var.aws_region, "a")
      map_public_ip_on_launch = true
    },
    {
      name                    = format("%s-%s-%s-private", var.project_suffix, var.aws_vpc_workload_b_name, var.project_suffix)
      owner                   = var.owner_tag
      cidr_block              = var.aws_subnet_workload_b_private_cidr
      custom_tags             = local.custom_tags
      availability_zone       = format("%s%s", var.aws_region, "a")
      map_public_ip_on_launch = false
    }
  ]
  providers = {
    aws = aws.default
  }
}

module "aws_security_group_generator_instance_public" {
  source                      = "./modules/aws/security_group"
  description                 = "SG Generator outside interface"
  aws_vpc_id                  = module.workload_vpc_a.aws_vpc["id"]
  aws_security_group_name     = format("%s-%s-%s-public", var.project_prefix, var.aws_ec2_generator_instance_name, var.project_suffix)
  security_group_rules_egress = [
    {
      ip_protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  security_group_rules_ingress = [
    {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  providers = {
    aws = aws.default
  }
}

module "aws_security_group_generator_instance_private" {
  source                  = "./modules/aws/security_group"
  aws_vpc_id              = module.workload_vpc_a.aws_vpc["id"]
  description             = "SG Generator instance inside interface"
  aws_security_group_name = format("%s-%s-%s-private", var.project_prefix, var.aws_ec2_generator_instance_name, var.project_suffix)

  providers = {
    aws = aws.default
  }
  security_group_rules_egress = [
    {
      ip_protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  security_group_rules_ingress = [
    {
      ip_protocol = "-1"
      cidr_blocks = ["10.0.0.0/8"]
    },
    {
      ip_protocol = "-1"
      cidr_blocks = ["172.16.0.0/16"]
    },
    {
      ip_protocol = "-1"
      cidr_blocks = ["192.168.0.0/16"]
    }
  ]
}

module "aws" {
  source                         = "./modules/f5xc/site/aws/tgw"
  f5xc_tenant                    = var.f5xc_tenant
  f5xc_api_url                   = var.f5xc_api_url
  f5xc_aws_cred                  = var.f5xc_aws_creds
  f5xc_api_token                 = var.f5xc_api_token
  f5xc_namespace                 = var.f5xc_namespace
  f5xc_aws_region                = var.aws_region
  f5xc_aws_tgw_name              = format("%s-%s-%s", var.project_prefix, var.aws_tgw_name, var.project_suffix)
  f5xc_aws_tgw_owner             = "c.klewar@ves.io"
  f5xc_aws_tgw_no_worker_nodes   = true
  f5xc_aws_default_ce_os_version = true
  f5xc_aws_default_ce_sw_version = true
  f5xc_aws_tgw_primary_ipv4      = var.f5xc_aws_tgw_primary_ipv4
  f5xc_aws_vpc_attachment_ids    = [module.workload_vpc_a.aws_vpc["id"], module.workload_vpc_b.aws_vpc["id"]]
  f5xc_aws_tgw_az_nodes          = {
    node0 : {
      f5xc_aws_tgw_workload_subnet = "192.168.168.0/26",
      f5xc_aws_tgw_inside_subnet   = "192.168.168.64/26",
      f5xc_aws_tgw_outside_subnet  = "192.168.168.128/26",
      f5xc_aws_tgw_az_name         = format("%s%s", var.aws_region, "a")
    },
    node1 : {
      f5xc_aws_tgw_workload_subnet = "192.168.169.0/26",
      f5xc_aws_tgw_inside_subnet   = "192.168.169.64/26",
      f5xc_aws_tgw_outside_subnet  = "192.168.169.128/26",
      f5xc_aws_tgw_az_name         = format("%s%s", var.aws_region, "b")
    },
    node2 : {
      f5xc_aws_tgw_workload_subnet = "192.168.170.0/26",
      f5xc_aws_tgw_inside_subnet   = "192.168.170.64/26",
      f5xc_aws_tgw_outside_subnet  = "192.168.170.128/26",
      f5xc_aws_tgw_az_name         = format("%s%s", var.aws_region, "c")
    }
  }
  ssh_public_key = file(var.ssh_public_key_file)
  custom_tags    = local.custom_tags
  providers      = {
    aws      = aws.default
    volterra = volterra.default
  }
}

module "apply_timeout_workaround" {
  source         = "./modules/utils/timeout"
  depend_on      = module.aws.f5xc_aws_tgw
  create_timeout = "120s"
  delete_timeout = "180s"
}

module "generator" {
  source                           = "./modules/aws/ec2"
  owner                            = var.owner_tag
  custom_tags                      = local.custom_tags
  aws_region                       = var.aws_region
  aws_az_name                      = format("%s%s", var.aws_region, "a")
  aws_ec2_instance_name            = format("%s-%s-%s", var.project_prefix, var.aws_ec2_generator_instance_name, var.project_suffix)
  aws_ec2_instance_type            = var.aws_ec2_generator_instance_type
  aws_ec2_instance_script_file     = var.aws_ec2_generator_instance_script_file_name
  aws_ec2_instance_script_template = var.aws_ec2_generator_instance_script_template_file_name
  aws_ec2_instance_script          = {
    actions = [
      format("chmod +x /tmp/%s", format("%s", var.aws_ec2_generator_instance_script_file_name)),
      format("sudo /tmp/%s", format("%s", var.aws_ec2_generator_instance_script_file_name))
    ]
    template_data = {
      PREFIX  = var.f5xc_aws_tgw_primary_ipv4
      GATEWAY = cidrhost(module.workload_subnets_a.aws_subnets[format("%s-%s-%s-private", var.project_suffix, var.aws_vpc_workload_a_name, var.project_suffix)]["cidr_block"], 1)
      HOST    = module.aws.f5xc_aws_tgw["nodes"]["master-0"]["interfaces"]["slo"]["public_ip"]
      PORT    = 80
    }
  }
  aws_ec2_network_interfaces = [
    {
      create_eip      = true
      private_ips     = var.aws_ec2_generator_instance_public_ips
      subnet_id       = module.workload_subnets_a.aws_subnets[format("%s-%s-%s-public", var.project_suffix, var.aws_vpc_workload_a_name, var.project_suffix)]["id"]
      custom_tags     = merge({ "Owner" : var.owner_tag }, local.custom_tags)
      security_groups = [module.aws_security_group_generator_instance_public.aws_security_group["id"]]
    },
    {
      create_eip      = false
      private_ips     = var.aws_ec2_generator_instance_private_ips
      security_groups = [module.aws_security_group_generator_instance_private.aws_security_group["id"]]
      subnet_id       = module.workload_subnets_a.aws_subnets[format("%s-%s-%s-private", var.project_suffix, var.aws_vpc_workload_a_name, var.project_suffix)]["id"]
      custom_tags     = merge({ "Owner" : var.owner_tag }, local.custom_tags)
    }
  ]
  aws_ec2_instance_custom_data_dirs = [
    {
      name        = "instance_script"
      source      = "${local.template_output_dir_path}/${var.aws_ec2_generator_instance_script_file_name}"
      destination = format("/tmp/%s", var.aws_ec2_generator_instance_script_file_name)
    }
  ]
  ssh_private_key          = file(var.ssh_private_key_file)
  ssh_public_key           = file(var.ssh_public_key_file)
  template_input_dir_path  = local.template_input_dir_path
  template_output_dir_path = local.template_output_dir_path
  providers                = {
    aws = aws.default
  }
}