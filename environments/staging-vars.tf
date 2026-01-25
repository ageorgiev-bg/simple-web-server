region               = "eu-west-1"
environment          = "staging"
app_name             = "web-app"
instance_tenancy     = "default"
instance_type        = "t4g.small"
db_instance_type     = "db.t4g.medium"
ipv4_main_cidr_block = "10.0.0.0/16"

enable_internet_gateway   = true
enable_single_nat_gateway = true

enable_s3_interface_endpoint  = false
enable_ssm_interface_endpoint = false


private_subnets_config = {
  private-subnet-1 = {
    az   = "euw1-az1"
    cidr = "10.0.1.0/24"
  }
  private-subnet-2 = {
    az   = "euw1-az2"
    cidr = "10.0.2.0/24"
  }
  private-subnet-3 = {
    az   = "euw1-az3"
    cidr = "10.0.3.0/24"
  }
}

public_subnets_config = {
  public-subnet-1 = {
    az   = "euw1-az1"
    cidr = "10.0.128.0/24"
  }
  public-subnet-2 = {
    az   = "euw1-az2"
    cidr = "10.0.129.0/24"
  }
  public-subnet-3 = {
    az   = "euw1-az3"
    cidr = "10.0.130.0/24"
  }
}