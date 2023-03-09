# part1 create vpc and its subnets
variable "aws_profile" {
  description = "The AWS CLI profile to use"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to use"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr_blocks" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnet_availability_zones" {
  description = "List of availability zones for public subnets"
  type        = list(string)
}

variable "private_subnet_availability_zones" {
  description = "List of availability zones for private subnets"
  type        = list(string)
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = var.vpc_name
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.public_subnet_availability_zones[count.index]


  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.private_subnet_availability_zones[count.index]

  tags = {
    Name = "${var.vpc_name}-private-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-internet-gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "${var.vpc_name}-public-route-table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-private-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  for_each = { for idx, subnet in aws_subnet.public_subnet : idx => subnet }

  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  for_each = { for idx, subnet in aws_subnet.private_subnet : idx => subnet }

  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.private_route_table.id
}

# part2 DB Security Group, S3 Bucket,
variable "security_group_name_prefix" {}
variable "ami_id" {}
variable "key_pair_name" {}

# Create an application security group
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

# 2.1 create db_security_group
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

resource "random_id" "random_id" {
  byte_length = 4
}

resource "aws_kms_key" "sse_kms_key" {
  description         = "KMS key for S3 server-side encryption"
  enable_key_rotation = true
}

# 2.2 Create a private S3 bucket with a randomly generated bucket name depending on the environment
resource "aws_s3_bucket" "private_bucket" {
  bucket = "${terraform.workspace}-bucket-${random_id.random_id.hex}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.sse_kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_configuration" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    id     = "lifecycle_configuration_rule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    filter {
      prefix = ""
    }
  }
}

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

# 2.5 User Data
data "template_file" "user_data" {
  template = <<-EOF
              #!/bin/bash
              export DB_HOSTNAME=${aws_db_instance.db_instance.endpoint}
              export DB_USERNAME=csye6225
              export DB_PASSWORD=password
              export S3_BUCKET_NAME=${aws_s3_bucket.private_bucket.bucket}


              # Install required software, clone your application code from Git, etc.
              sudo yum update -y
              sudo yum install -y maven
              sudo yum install -y git
              git clone git@github.com:ZhengruiLu/webapp.git

              # Build the application
              cd ./ProductManager
              mvn clean install

              # Move the JAR file to deployment directory
              sudo mkdir /opt/deployment
              sudo cp ./ProductManager/target/ProductManager-0.0.1-SNAPSHOT.jar /opt/deployment/
              sudo chown -R $USER:$USER /opt/deployment

              # Create systemd service file
              sudo cp ./scripts/ProductManager.service /etc/systemd/system/
              sudo systemctl daemon-reload
              sudo systemctl enable ProductManager.service
              sudo systemctl start ProductManager.service
              sudo systemctl status ProductManager.service

              EOF
}

# 2.6 IAM Policy
resource "aws_iam_policy" "webapp_s3_policy" {
  name = "webapp-s3-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowGroupToSeeBucketListInTheConsole",
        "Effect" : "Allow",
        "Action" : ["s3:ListBucket", "s3:GetBucketLocation"],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}/*"
        ]
      },
      {
        "Sid" : "AllowUserSpecificActionsOnlyInTheSpecificUserPrefix",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetObjectAcl",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}/*"
        ]
      }
    ]
  })
}

# 2.7 IAM Role
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
  name       = "ec2_policy_attachment"
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
  roles      = [aws_iam_role.ec2_role.id]
}

# Create the EC2 instance
resource "aws_instance" "my_ec2_instance" {
  for_each = { for idx, subnet in aws_subnet.public_subnet : idx => subnet }

  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_security_group.id]
  subnet_id              = aws_subnet.public_subnet[each.key].id
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

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "rds-subnet-group"
  description = "Subnet group for RDS instances"

  subnet_ids = [for subnet in aws_subnet.private_subnet : subnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}
