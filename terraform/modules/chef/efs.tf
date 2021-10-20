# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system
resource "aws_efs_file_system" "research_shared_fs" {
  creation_token         = "research-shared-fs"
  availability_zone_name = aws_subnet.default_subnet.availability_zone
  encrypted              = true
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "core_mnt_target" {
  file_system_id = aws_efs_file_system.research_shared_fs.id
  subnet_id      = aws_subnet.default_subnet.id
  security_groups = [
    aws_security_group.allow_vpc_traffic_sg.id
  ]
}


