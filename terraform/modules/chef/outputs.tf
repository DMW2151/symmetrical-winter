output "core-infra-vpc" {
  value = aws_vpc.infra-vpc
}

output "chef-workstation-ip" {
  value = aws_instance.chef-workstation.public_ip
}

output "ssh_group_id" {
  value = aws_security_group.allow_deployer_sg.id
}
