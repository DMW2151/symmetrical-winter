resource "aws_route_table" "main" {

  # Basic
  vpc_id = aws_vpc.infra-vpc.id

  # Routes
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.core-igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.core-igw.id
  }

  tags = {
    Name   = "Infra VPC - Main Route Table"
    Module = "Chef Server - Core Networking"
  }
}

resource "aws_main_route_table_association" "asc-main-vpc" {
  vpc_id         = aws_vpc.infra-vpc.id
  route_table_id = aws_route_table.main.id
}
