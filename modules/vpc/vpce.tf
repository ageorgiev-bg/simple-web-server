# VPC Interface Endpoint for S3

resource "aws_vpc_endpoint" "interface_endpoint_s3" {
  count               = var.interface_endpoint_s3 ? 1 : 0
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*] #data.aws_subnets.private.ids
  service_name        = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  dns_options { private_dns_only_for_inbound_resolver_endpoint = false }
  tags = var.tags
}

resource "aws_vpc_endpoint_subnet_association" "association_endpoint_s3" {
  for_each        = var.interface_endpoint_s3 ? aws_subnet.private : {}
  subnet_id       = each.value.id
  vpc_endpoint_id = aws_vpc_endpoint.interface_endpoint_s3[0].id
}


# VPC Interface Endpoints for AWS SSM (ssm, ssmmessages, ec2messages)

resource "aws_vpc_endpoint" "interface_endpoint_ssm" {
  count               = var.interface_endpoint_ssm ? 1 : 0
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*] #data.aws_subnets.private.ids
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ssm"
  private_dns_enabled = true

  tags = var.tags
}

resource "aws_vpc_endpoint_subnet_association" "association_endpoint_ssm" {
  for_each        = var.interface_endpoint_ssm ? aws_subnet.private : {}
  subnet_id       = each.value.id
  vpc_endpoint_id = aws_vpc_endpoint.interface_endpoint_ssm[0].id
}

resource "aws_vpc_endpoint" "interface_endpoint_ssmmsg" {
  count               = var.interface_endpoint_ssm ? 1 : 0
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*] #data.aws_subnets.private.ids
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  private_dns_enabled = true

  tags = var.tags
}

resource "aws_vpc_endpoint_subnet_association" "association_endpoint_ssmmsg" {
  for_each        = var.interface_endpoint_ssm ? aws_subnet.private : {}
  subnet_id       = each.value.id
  vpc_endpoint_id = aws_vpc_endpoint.interface_endpoint_ssmmsg[0].id
}

resource "aws_vpc_endpoint" "interface_endpoint_ec2msg" {
  count               = var.interface_endpoint_ssm ? 1 : 0
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*] #data.aws_subnets.private.ids
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  private_dns_enabled = true

  tags = var.tags
}

resource "aws_vpc_endpoint_subnet_association" "association_endpoint_ec2msg" {
  for_each        = var.interface_endpoint_ssm ? aws_subnet.private : {}
  subnet_id       = each.value.id
  vpc_endpoint_id = aws_vpc_endpoint.interface_endpoint_ec2msg[0].id
}