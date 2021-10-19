# Create Core VPC for the Hub Service

# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "infra-vpc" {

  cidr_block           = "192.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true


  tags = {
    Name   = "Infrastructure - Core VPC"
    Module = "Chef Server - Core Networking"
  }
}