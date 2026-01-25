# VPC + IGW + NAT GW

resource "aws_vpc" "main" {
  cidr_block           = var.ipv4_primary_cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, { "Provisioned by" = "Terraform" })
}

resource "aws_internet_gateway" "main" {
  count  = var.internet_gateway_enabled ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = var.tags
}

# Single NAT GW per VPC
resource "aws_nat_gateway" "nat" {
  count         = var.nat_gateway_enabled && var.internet_gateway_enabled ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  region        = var.region
  subnet_id     = element(values(aws_subnet.public)[*].id, count.index)

  tags = var.tags

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "nat" {
  count  = var.nat_gateway_enabled && var.internet_gateway_enabled ? 1 : 0
  domain = "vpc"

  tags = var.tags
}



# VPC route tables

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  region                 = var.region

  route = []

  # tags = merge(var.tags, { Name = "default-route-table" })
}

resource "aws_route_table" "private_ipv4_egress" {
  count  = var.nat_gateway_enabled && var.internet_gateway_enabled ? 1 : 0
  vpc_id = aws_vpc.main.id
  region = var.region

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[0].id
  }

  # tags = merge(var.tags, { Name = "natgw-ipv4-egress" })
}

resource "aws_route_table_association" "private_zones" {
  for_each       = var.nat_gateway_enabled && var.internet_gateway_enabled ? aws_subnet.private : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_ipv4_egress[0].id
}

resource "aws_route_table" "public" {
  count  = var.internet_gateway_enabled ? 1 : 0
  vpc_id = aws_vpc.main.id
  region = var.region

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(var.tags, { Name = "igw-ipv4-egress" })
}

resource "aws_route_table_association" "public_zones" {
  for_each       = var.internet_gateway_enabled ? aws_subnet.public : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}