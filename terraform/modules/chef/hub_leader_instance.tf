
# EC2 Instance that hosts the Chef Server

# Resource: https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file
data "template_file" "hub-leader-userdata" {
  template = filebase64("./../modules/chef/user_data/hubserver_userdata.sh")
}

# Need an instance that can be used as the Chef Server
# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "hub-leader" {

  # Basic Config - Use t3.medium running Ubuntu:20.04 w. VCPU + 4GB Memory + Configurable Storage (20GB)
  # Should be fine for our very basic Chef server deployment...
  ami           = data.aws_ami.ubuntu-chef-client.image_id
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

  # Storage
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    tags = {
      Name   = "Chef Server - Jupyter Hub - Root Volume"
      Module = "Chef Server - Core Networking"
    }
  }

  # User Data
  # See `build_chef_server.sh` for details, builds a Chef Server for Ubuntu 20.04 w. all deps 
  user_data            = data.template_file.hub-leader-userdata.rendered
  iam_instance_profile = aws_iam_instance_profile.chef_server_profile.name

  # Monitoring & Metadata Mgmt - [NOTE]: These are default options; Added for clarity
  monitoring = true
  metadata_options {
    http_endpoint = "enabled"
  }

  depends_on = [
    null_resource.wait_for_workstation_init,
    aws_instance.chef-workstation
  ]

  # Tags
  tags = {
    Name   = "Chef - Jupyter Hub Master"
    Module = "Chef Server - Core Networking"
  }

}