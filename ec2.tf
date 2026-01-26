### Compute Resources: (AMI, EC2, ASG, Launch Template)
data "aws_ami" "ec2_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*.0-kernel-6.12-arm64"]
  }
}

resource "aws_launch_template" "app_asg_lt" {
  name_prefix   = "${var.app_name}-${var.environment}-"
  image_id      = data.aws_ami.ec2_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.asg_sg.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
    }
  }

  iam_instance_profile {
    name = "EC2InstanceRoleAdm"
  }

  user_data = base64encode(templatefile(
    "${path.root}/scripts/user_data_v2.sh",
    {
      web_app     = var.app_name,
      environment = var.environment,
      db_endpoint = aws_rds_cluster.web_app_db.endpoint
      admin_creds = var.db_admin_creds # received from CI/CD pipeline
    }
  ))
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-asg-lt"
    Environment = var.environment
  }

}

resource "aws_autoscaling_group" "app_asg" {
  name                      = "${var.app_name}-${var.environment}"
  target_group_arns         = [aws_lb_target_group.web_app_tg.arn, ]
  vpc_zone_identifier       = module.vpc.private_subnets
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB" # ELB Target Group health checks + ASG health checks
  desired_capacity          = 1
  force_delete              = true

  launch_template {
    id      = aws_launch_template.app_asg_lt.id
    version = "$Latest"
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "Application"
    value               = var.app_name
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = false
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 0
    }

    triggers = ["tag"] # additional triggers besides launch_configuration, launch_template, or mixed_instances_policy
  }

  depends_on = [
    aws_rds_cluster.web_app_db
  ]

}