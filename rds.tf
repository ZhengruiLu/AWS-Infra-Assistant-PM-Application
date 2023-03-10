# 2.3 RDS Parameter Group
resource "aws_db_parameter_group" "db_parameter_group" {
  name   = "my-rds-pg"
  family = "mariadb10.5"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 2.4 RDS Instance
resource "aws_db_instance" "db_instance" {
  engine                 = "mariadb"
  engine_version         = "10.5"
  instance_class         = "db.t2.micro"
  multi_az               = false
  identifier             = "csye6225"
  username               = "csye6225"
  password               = "password"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  parameter_group_name   = aws_db_parameter_group.db_parameter_group.name
  skip_final_snapshot    = true
  publicly_accessible    = false
  apply_immediately      = true
  allocated_storage      = 20
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
}
