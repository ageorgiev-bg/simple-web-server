## ELB Resources (Load Balancer, Target Group, Listeners, S3 log bucket)

locals {
  # tflint-ignore: terraform_unused_declarations
  elb_listener_cert = "arn:aws:acm:${var.region}:${data.aws_caller_identity.current.account_id}:certificate/ef104088-5fc4-4f69-91b6-813b7a27dadb" # "Custom self-signed TLS certificate for ELB HTTPS listener."
}

resource "aws_s3_bucket" "lb_logs" {
  bucket        = "${var.app_name}-${var.environment}-elb-logs"
  force_destroy = true

  tags = {
    Name        = "${var.app_name}-${var.environment}-elb-logs"
    Environment = var.environment
    Region      = var.region
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.lb_logs.id
  policy = data.aws_iam_policy_document.allow_access_to_elb.json
}

data "aws_iam_policy_document" "allow_access_to_elb" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.lb_logs.arn,
      "${aws_s3_bucket.lb_logs.arn}/*",
    ]
  }
}

resource "aws_lb_target_group" "web_app_tg" {
  name        = "${var.app_name}-${var.environment}-alb-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  target_health_state {
    enable_unhealthy_connection_termination = false
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-elb-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "web_app_listener_https" {
  load_balancer_arn = aws_lb.web_app_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.elb_listener_cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_tg.arn
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-elb-lt"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "web_app_listener_redir" {
  load_balancer_arn = aws_lb.web_app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-elb-lt"
    Environment = var.environment
  }
}

resource "aws_lb" "web_app_lb" {
  name               = "${var.app_name}-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = module.vpc.public_subnets

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "${var.app_name}-${var.environment}"
    enabled = true
  }

  tags = {
    Environment = var.environment
  }
}


