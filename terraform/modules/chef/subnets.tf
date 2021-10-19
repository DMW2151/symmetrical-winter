# Create public and private subnets in two AZs in the same region...

# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "default_subnet" {

  # Basic
  vpc_id                  = aws_vpc.infra-vpc.id
  cidr_block              = "192.0.0.0/18"
  availability_zone       = var.default_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name   = "Chef - Deafult Infra Subnet"
    Module = "Chef Server - Core Networking"
  }
}

resource "aws_subnet" "default_subnet_2" {

  # Basic
  vpc_id                  = aws_vpc.infra-vpc.id
  cidr_block              = "192.0.64.0/18"
  availability_zone       = var.secondary_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name   = "Chef - Deafult Infra Subnet"
    Module = "Chef Server - Core Networking"
  }
}