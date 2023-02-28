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
variable "subnet_id" {}

# Define the AMI ID, key pair name, and security group name prefix
variable "ami_id" {}
variable "key_pair_name" {}
variable "security_group_name_prefix" {}
variable "bucket_name" {}

# Create an application security group
resource "aws_security_group" "app" {
  name_prefix = var.security_group_name_prefix
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
  vpc_security_group_ids = [aws_security_group.app.id]
  subnet_id              = var.subnet_id
  key_name               = var.key_pair_name

  # Disable termination protection
  #  disable_api_termination = true

  # Define the root volume with size and type
  root_block_device {
    volume_size           = 50
    volume_type           = "gp2"
    delete_on_termination = true
  }

  # Restart the MariaDB service on reboot
  user_data = <<-EOF
              #!/bin/bash
              # Set the bucket name
              export BUCKET_NAME=bucket_name

              # Install the AWS CLI
              apt-get update
              apt-get install -y awscli

              # Create a directory and download the jar from S3
              mkdir /data
              aws s3 cp s3://${BUCKET_NAME}/ProductManager-0.0.1-SNAPSHOT.jar /data/

              # Run the Maven project
              cd /data
              mvn spring-boot:run
              EOF
}
