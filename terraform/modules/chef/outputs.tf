output "core-infra-vpc" {
  value = aws_vpc.infra-vpc
}

output "chef-workstation-ip" {
  value = aws_instance.chef-workstation.public_ip
}
