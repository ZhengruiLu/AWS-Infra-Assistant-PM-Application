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

variable "security_group_name_prefix" {}
variable "ami_id" {}
variable "key_pair_name" {}

variable "zone_name" {
  description = "Name of the Route53 zone"
  default     = null
}

variable "port" {
  description = "Port on which the web application is running"
  default     = 8080
}
