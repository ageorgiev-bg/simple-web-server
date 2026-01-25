# ELB Security Group
resource "aws_security_group" "elb_sg" {
  name        = "${var.app_name}-${var.environment}-elb"
  description = "Allow HTTP/S inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.app_name}-${var.environment}-elb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "elb_allow_http_ipv4" {
  security_group_id = aws_security_group.elb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "elb_allow_https_ipv4" {
  security_group_id = aws_security_group.elb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "elb_allow_all_ipv4" {
  security_group_id = aws_security_group.elb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

## EC2 Security Group
resource "aws_security_group" "asg_sg" {
  name        = "${var.app_name}-${var.environment}-asg"
  description = "Allow HTTPS/HTTP inbound traffic and all outbound traffic"
  vpc_id      = tostring(module.vpc.vpc_id)

  tags = {
    Name = "${var.app_name}-${var.environment}-asg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "asg_allow_http_ipv4" {
  security_group_id            = aws_security_group.asg_sg.id
  referenced_security_group_id = aws_security_group.elb_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "asg_allow_https_ipv4" {
  security_group_id            = aws_security_group.asg_sg.id
  referenced_security_group_id = aws_security_group.elb_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "asg_allow_egress_ipv4" {
  security_group_id = aws_security_group.asg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


# RDS DB security Group
resource "aws_security_group" "rds_sg" {
  name        = "${var.app_name}-${var.environment}-rds"
  description = "Allow app inbound traffic and all outbound traffic"
  vpc_id      = tostring(module.vpc.vpc_id)

  tags = {
    Name = "${var.app_name}-${var.environment}-rds"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_allow_app_ipv4" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.asg_sg.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}


resource "aws_vpc_security_group_egress_rule" "rds_allow_egress_ipv4" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}