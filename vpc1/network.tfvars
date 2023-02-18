#aws_profile = "demo2"
#aws_region  = "us-west-2"

vpc_name = "terraform created"

vpc_cidr_block = "10.0.0.0/24"

public_subnet_cidr_blocks = [
  "10.0.0.16/28",
  "10.0.0.32/27",
  "10.0.0.96/27"
]

private_subnet_cidr_blocks = [
  "10.0.0.0/28",
  "10.0.0.128/26",
  "10.0.0.192/26"
]

public_subnet_availability_zones = [
  "us-west-2a",
  "us-west-2b",
  "us-west-2c"
]

private_subnet_availability_zones = [
  "us-west-2a",
  "us-west-2b",
  "us-west-2c"
]
