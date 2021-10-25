
# EC2 Instance that hosts the Chef Server

# Resource: https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file
data "template_file" "workstation-userdata" {
  template = filebase64("./../modules/chef/user_data/workstation_userdata.sh")
}


resource "time_sleep" "wait_chef_server_stable_30s" {
  depends_on      = [aws_instance.chef-server]
  create_duration = "30s"
}


data "aws_ami" "ubuntu-chef-workstation" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "ubuntu-*-chef-workstation-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = [
    var.aws_account_id
  ]
}

# Need an instance that can be used as the Chef Server
# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "chef-workstation" {

  # Basic Config - Use t3.medium running Ubuntu:20.04 w. VCPU + 4GB Memory + Configurable Storage (20GB)
  # Should be fine for our very basic Chef server deployment...
  ami           = data.aws_ami.ubuntu-chef-workstation.image_id
  instance_type = "t3.small"
  ebs_optimized = true

  # Security + Networking
  # [TODO][PENDING]: For debugging - Allow direct SSH access to Chef Server from (my machine), 
  # consider changing s.t. the instance doesn't need a public IP && maintenance done through 
  # a jump server, still need a DNS though...
  availability_zone           = aws_subnet.default_subnet.availability_zone
  subnet_id                   = aws_subnet.default_subnet.id
  associate_public_ip_address = true
  key_name                    = "public-jump-1"
  vpc_security_group_ids = [
    aws_security_group.allow_vpc_traffic_sg.id,
    aws_security_group.allow_deployer_sg.id,
    aws_security_group.allow_deployer_http_sg.id,
    aws_security_group.allow_all_http_sg.id
  ]

  # User Data - See `build_chef_server.sh` for details
  user_data            = data.template_file.workstation-userdata.rendered
  iam_instance_profile = aws_iam_instance_profile.chef_server_profile.name

  # Monitoring & Metadata Mgmt - [NOTE]: These are default options; Added for clarity
  monitoring = true
  metadata_options {
    http_endpoint = "enabled"
  }

  # Depends on - Give all peripheral instances an explicit dependency on the Server
  depends_on = [
    aws_instance.chef-server, time_sleep.wait_chef_server_stable_30s
  ]

  # Tags
  tags = {
    Name   = "Chef - Workstation"
    Module = "Chef Server - Core Networking"
  }

}