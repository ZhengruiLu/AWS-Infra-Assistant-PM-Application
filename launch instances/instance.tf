# this file create vpc, bucket, and subnet

# Define the provider and AWS region
variable "aws_region" {
  description = "AWS region to use"
  default     = "us-west-1"
}

provider "aws" {
  region = var.aws_region
}

# Define the VPC and subnet IDs
variable "vpc_id" {}
variable "subnet_id_public" {}
variable "private_subnet_ids" {
  type    = list(string)
  default = []
}

# Define the AMI ID, key pair name, and security group name prefix
variable "ami_id" {}
variable "key_pair_name" {}
variable "security_group_name_prefix" {}
#variable "bucket_name" {}

# Create an application security group
resource "aws_security_group" "app_security_group" {
  name_prefix = var.security_group_name_prefix
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the EC2 instance
resource "aws_instance" "my_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_security_group.id]
  subnet_id              = var.subnet_id_public
  key_name               = var.key_pair_name

  # Disable termination protection
  #  disable_api_termination = true

  # Define the root volume with size and type
  root_block_device {
    volume_size           = 50
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = data.template_file.user_data.rendered
}

resource "aws_security_group" "db_security_group" {
  name_prefix = "db-"

  ingress {
    from_port = 3306 # for MySQL/MariaDB or 5432 for PostgreSQL
    to_port   = 3306 # for MySQL/MariaDB or 5432 for PostgreSQL
    protocol  = "tcp"
    security_groups = [
      aws_security_group.app_security_group.id
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  vpc_id = var.vpc_id

  tags = {
    Name = "DB Security Group"
  }
}

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

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "rds-subnet-group"
  description = "Subnet group for RDS instances"

  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "db_instance" {
  engine               = "mariadb"
  engine_version       = "10.5"
  instance_class       = "db.t2.micro"
  multi_az             = false
  identifier           = "csye6225"
  username             = "csye6225"
  password             = "password"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  parameter_group_name = aws_db_parameter_group.db_parameter_group.name
  skip_final_snapshot  = true
  publicly_accessible  = false
  apply_immediately    = true
  allocated_storage    = 20
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
}

#user data
variable "s3_bucket_name" {}

data "template_file" "user_data" {
  template = <<-EOF
              #!/bin/bash
              export DB_HOSTNAME=${aws_db_instance.db_instance.endpoint}
              export DB_USERNAME=csye6225
              export DB_PASSWORD=password
              export S3_BUCKET_NAME=${var.s3_bucket_name}

              # Install required software, clone your application code from Git, etc.
              # ...
              EOF
}

resource "aws_iam_policy" "webapp_s3_policy" {
  name        = "webapp-s3-policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "EC2-CSYE6225"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "EC2 Role for CSYE6225"
  }
}

resource "aws_iam_policy_attachment" "ec2_policy_attachment" {
  name = "ec2_policy_attachment"
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
  roles      = [aws_iam_role.ec2_role.id]
}



