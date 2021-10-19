resource "aws_internet_gateway" "core-igw" {

  vpc_id = aws_vpc.infra-vpc.id

  tags = {
    Name   = "Chef Server - IGW to Core VPC"
    Module = "Chef Server - Core Networking"
  }

}