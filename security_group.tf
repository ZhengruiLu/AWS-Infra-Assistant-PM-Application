#1. variables
#2. networking
#3. Create an application security group
resource "aws_security_group" "app_security_group" {
  name_prefix = var.security_group_name_prefix
  vpc_id      = aws_vpc.vpc.id

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

#4. Create db_security_group
resource "aws_security_group" "db_security_group" {
  name_prefix = "db-"

  ingress {
    from_port = 3306 # for MySQL/MariaDB
    to_port   = 3306
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

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "DB Security Group"
  }
}

#5. S3 bucket

#6. User Data

#7. IAM Policy


