# AWS Security Group - A very permissive group that allows any resource in the VPC to
# communicate with any other, provided the ports are configured properly && have no other 
# firewalls, extra ACLs, etc...


# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "allow_all_http_sg" {

  # General
  name                   = "allow_all_http_sg"
  vpc_id                 = aws_vpc.infra-vpc.id
  description            = "Allows all HTTP(S) access.."
  revoke_rules_on_delete = true

  # Ingress/Egress Rules
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name   = "Chef Server - Allow Internet HTTP Traffic"
    Module = "Chef Server - Core Networking"
  }

}

# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "allow_vpc_traffic_sg" {

  # General
  name                   = "allow_vpc_traffic_sg"
  vpc_id                 = aws_vpc.infra-vpc.id
  description            = "Allows all access (ingress + egress) from within the VPC on all ports"
  revoke_rules_on_delete = true

  # Ingress/Egress Rules
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      aws_vpc.infra-vpc.cidr_block
    ]
    self = true
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      aws_vpc.infra-vpc.cidr_block
    ]
    self = true
  }

  tags = {
    Name   = "Chef Server - Allow All VPC Traffic"
    Module = "Chef Server - Core Networking"
  }

}

# AWS Security Group - A group that allows SSH access from the IP of the developer into any resource
# running SSH (provided they have the key, of course!)
# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "allow_deployer_sg" {

  # General
  name                   = "allow_deployer_sg"
  vpc_id                 = aws_vpc.infra-vpc.id
  description            = "Allows SSH access from the IP of the terraform user, most likely myself..."
  revoke_rules_on_delete = true

  # Ingress/Egress Rules
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "TCP"
    cidr_blocks = [
      var.deployer_ip
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name   = "Chef Server - Allow Deployer SSH"
    Module = "Chef Server - Core Networking"
  }

}


resource "aws_security_group" "allow_deployer_http_sg" {

  # General
  name                   = "allow_deployer_http_sg"
  vpc_id                 = aws_vpc.infra-vpc.id
  description            = "Allows HTTPS access from the IP of the terraform user, most likely myself..."
  revoke_rules_on_delete = true

  # Ingress/Egress Rules
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      var.deployer_ip
    ]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      var.deployer_ip
    ]
  }





  tags = {
    Name   = "Chef Server - Allow Deployer SSH"
    Module = "Chef Server - Core Networking"
  }

}