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

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.vpc_name}-bucket-${random_id.random_id.hex}"
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "ProductManager-0.0.1-SNAPSHOT.jar"
  source = "D:/Project/network-structure-and-cloud-computing/a04-webapp/webapp/ProductManager/target/ProductManager-0.0.1-SNAPSHOT.jar"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("D:/Project/network-structure-and-cloud-computing/a04-webapp/webapp/ProductManager/target/ProductManager-0.0.1-SNAPSHOT.jar")
}

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
