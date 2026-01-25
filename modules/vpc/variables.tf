locals {
  availability_zones = distinct([
    for s in aws_subnet.private : s.availability_zone
  ])
}


variable "region" {
  description = "AWS Region."
  type        = string
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "A boolean flag to enable/disable DNS hostnames in the VPC. Defaults false."
}

variable "enable_dns_support" {
  description = "A boolean flag to enable/disable DNS support in the VPC. Defaults true."
  type        = bool
}

variable "ipv4_primary_cidr_block" {
  description = "Primary VPC CIDR block."
  type        = string
}

variable "vpc_name" {
  description = "VPC name."
  type        = string
}

variable "tags" {
  description = "Tags to assign to the resource."
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC."
}

variable "internet_gateway_enabled" {
  description = "A boolean flag to enable/disable the internet gateway."
  type        = bool
}
variable "nat_gateway_enabled" {
  description = "A boolean flag to enable/disable the NAT gateway."
  type        = bool
}

# variable "ipv4_cidr_block_association_timeouts" {
#   type = object({
#     create = string
#     delete = string
#   })
#   description = "Timeouts (in `go` duration format) for creating and destroying IPv4 CIDR block associations."
#   default     = null
# }

variable "private_subnets_config" {
  description = "Private subnets config map."
  type        = map(any)
}

variable "public_subnets_config" {
  description = "Public subnets config map."
  type        = map(any)
}

variable "interface_endpoint_s3" {
  description = "A boolean flag to enable/disable the S3 interface endpoint."
  type        = bool
}

variable "interface_endpoint_ssm" {
  description = "A boolean flag to enable/disable the SSM interface endpoint."
  type        = bool
}