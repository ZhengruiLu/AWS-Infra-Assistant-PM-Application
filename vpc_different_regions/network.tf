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

resource "random_id" "random_id" {
  byte_length = 4
}

resource "aws_kms_key" "sse_kms_key" {
  description         = "KMS key for S3 server-side encryption"
  enable_key_rotation = true
}

# Create a private S3 bucket with a randomly generated bucket name depending on the environment
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

