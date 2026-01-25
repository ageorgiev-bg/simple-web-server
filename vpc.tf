data "aws_caller_identity" "current" {}

module "vpc" {
  source                   = "./modules/vpc"
  vpc_name                 = var.environment
  region                   = var.region
  enable_dns_hostnames     = true
  enable_dns_support       = true
  instance_tenancy         = var.instance_tenancy
  ipv4_primary_cidr_block  = var.ipv4_main_cidr_block
  internet_gateway_enabled = var.enable_internet_gateway
  nat_gateway_enabled      = var.enable_single_nat_gateway
  interface_endpoint_s3    = var.enable_s3_interface_endpoint
  interface_endpoint_ssm   = var.enable_ssm_interface_endpoint
  private_subnets_config   = var.private_subnets_config
  public_subnets_config    = var.public_subnets_config

  tags = {
    Env   = var.environment,
    Owner = data.aws_caller_identity.current.account_id
  }

}

