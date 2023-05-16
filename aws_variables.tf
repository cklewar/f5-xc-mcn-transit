variable "f5xc_azure_vnet_primary_ipv4" {
  type    = string
  default = "10.130.0.0/21"
}

variable "f5xc_aws_creds" {
  type = string
}

variable "f5xc_aws_tgw_primary_ipv4" {
  type = string
}

variable "f5xc_aws_tgw_owner" {
  type = string
}

variable "aws_region" {
  type        = string
  description = "AWS region name"
}

variable "aws_tgw_name" {
  type        = string
  description = "TGW name"
}

variable "aws_vpc_workload_a_name" {
  type        = string
  description = "Name for workload vpc a"
}

variable "aws_vpc_workload_b_name" {
  type        = string
  description = "Name for workload vpc b"
}

variable "aws_vpc_workload_a_cidr_block" {
  type        = string
  description = "vpc cidr block for workload vpc a"
}

variable "aws_vpc_workload_b_cidr_block" {
  type        = string
  description = "vpc cidr block for workload vpc b"
}

variable "aws_subnet_workload_a_public_cidr" {
  type        = string
  description = "Workload A public net subnet"
}

variable "aws_subnet_workload_a_private_cidr" {
  type        = string
  description = "Workload A private net subnet"
}

variable "aws_subnet_workload_b_public_cidr" {
  type        = string
  description = "Workload B public net subnet"
}

variable "aws_subnet_workload_b_private_cidr" {
  type        = string
  description = "Workload B private net subnet"
}

variable "aws_ec2_generator_instance_script_file_name" {
  type        = string
  description = "EC2 instance script template file name"
}

variable "aws_ec2_generator_instance_name" {
  type        = string
  description = "EC2 traffic generator instance name"
}

variable "aws_ec2_generator_instance_type" {
  type        = string
  description = "EC2 traffic generator instance type"
}

variable "aws_ec2_generator_instance_private_ips" {
  type        = list(string)
  description = "AWS ec2 instance private interface static IP"
}

variable "aws_ec2_generator_instance_public_ips" {
  type        = list(string)
  description = "AWS ec2 instance public interface static IP"
}

variable "aws_ec2_generator_instance_script_template_file_name" {
  type    = string
  default = "generator.tftpl"
}