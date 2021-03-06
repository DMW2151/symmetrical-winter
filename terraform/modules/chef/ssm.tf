resource "aws_ssm_parameter" "chef_server_cfg" {
  name  = "chef_server_config"
  type  = "String"
  value = filebase64("./../modules/chef/config/chef_config.json")
}

resource "aws_ssm_parameter" "chef_server_ip" {
  name  = "chef_server_ip"
  type  = "String"
  value = aws_instance.chef-server.private_ip
}

resource "aws_ssm_parameter" "chef_server_dns" {
  name  = "chef_server_dns"
  type  = "String"
  value = aws_instance.chef-server.private_dns
}

resource "aws_ssm_parameter" "nfs_mount_ip" {
  name  = "nfs_mount_ip"
  type  = "String"
  value = aws_efs_mount_target.core_mnt_target.ip_address
}
