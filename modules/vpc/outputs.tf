output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC id."
}

output "cidr_block" {
  value       = aws_vpc.main.cidr_block
  description = "VPC cidr_block."
}

output "public_subnets" {
  value       = values(aws_subnet.public)[*].id #[for subnet in values(aws_subnet.public)[*] : subnet.id]
  description = "VPC cidr_block."
}

output "private_subnets" {
  value       = values(aws_subnet.private)[*].id # [for subnet in values(aws_subnet.private)[*] : subnet.id]
  description = "VPC cidr_block."
}

output "db_subnet_group_id" {
  value       = aws_db_subnet_group.db_subnet_group.id
  description = "VPC subnet group in private AZs."
}

output "private_subnet_availability_zones" {
  value       = local.availability_zones
  description = "VPC private subnet AZs."
}