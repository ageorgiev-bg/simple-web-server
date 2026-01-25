resource "aws_rds_cluster" "web_app_db" {
  cluster_identifier      = "${var.app_name}-${var.environment}"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.11.1"
  availability_zones      = module.vpc.private_subnet_availability_zones
  database_name           = "web_app"
  master_username         = "admin"
  master_password         = var.db_admin_creds # received from CI/CD pipeline
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  storage_encrypted       = true

  skip_final_snapshot = true

  db_subnet_group_name = module.vpc.db_subnet_group_id
  # db_cluster_parameter_group_name

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name        = "${var.app_name}-db"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "web_app_db_instance" {
  identifier_prefix  = var.app_name
  cluster_identifier = aws_rds_cluster.web_app_db.id

  engine         = aws_rds_cluster.web_app_db.engine
  engine_version = aws_rds_cluster.web_app_db.engine_version

  instance_class = var.db_instance_type

  #db_subnet_group_name = module.vpc.db_subnet_group_id # must match the same param defined on cluster level

  #db_parameter_group_name = aws_db_parameter_group.db_parameters.name

  tags = {
    Name        = "${var.app_name}-db"
    Environment = var.environment
  }
}
