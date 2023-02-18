vpc_name = "my-second-vpc"

vpc_cidr_block = "10.1.0.0/16"

public_subnet_cidr_blocks = [
  "10.1.0.0/24",
  "10.1.1.0/24",
  "10.1.2.0/24"
]

private_subnet_cidr_blocks = [
  "10.1.10.0/24",
  "10.1.11.0/24",
  "10.1.12.0/24"
]

public_subnet_availability_zones = [
  "us-west-2b",
  "us-west-2c",
  "us-west-2d"
]

private_subnet_availability_zones = [
  "us-west-2b",
  "us-west-2c",
  "us-west-2d"
]