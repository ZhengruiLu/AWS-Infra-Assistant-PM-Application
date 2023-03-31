aws_profile = "demo-S3"
aws_region  = "us-west-1"

vpc_name = "a06-vpc-created-by-terraform"

vpc_cidr_block = "10.1.0.0/16"

public_subnet_cidr_blocks = [
  "10.1.0.0/24",
  #  "10.1.1.0/24",
  #  "10.1.2.0/24"
]

private_subnet_cidr_blocks = [
  "10.1.10.0/24",
  "10.1.11.0/24",
  "10.1.12.0/24"
]

public_subnet_availability_zones = [
  "us-west-1a",
  #    "us-west-1c",
  #    "us-west-1d"
]

private_subnet_availability_zones = [
  "us-west-1a",
  "us-west-1c",
  "us-west-1c",
]

security_group_name_prefix = "mysg"
ami_id                     = "ami-044a36875c1f626c8"
key_pair_name              = "aws-demo-us-west-1"
zone_name                  = "demo.zltech.me"
port                       = 80