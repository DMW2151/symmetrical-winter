# Configures core EC2 Instance that hosts the Chef Server

# Resource: https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file
data "template_file" "chef-infra-server-userdata" {
  template = filebase64("./../modules/chef/user_data/build_chef_server.sh")
}


resource "null_resource" "wait_for_chef_init" {

  # Suggestion: https://rpadovani.com/terraform-cloudinit
  provisioner "local-exec" {

    interpreter = ["/bin/sh", "-c"]
    command     = <<-EOF
    set -x -Ee -o pipefail;

    # Small Buffer to Ensure Instance is Up - Could be a Null Resource
    sleep 30;
    export isalpine=$(uname -a | grep -iE alpine)

    if [ ! -z "$isalpine" ]; then
      apk update &&\
        apk add aws-cli
    else
      DEBIAN_FRONTEND=noninteractive
      wget http://security.ubuntu.com/ubuntu/pool/main/a/apt/apt_2.0.2_amd64.deb
      dpkg -i apt_2.0.2_amd64.deb
      apt-get update &&\
        apt-get install -y awscli 
    fi
    
    export command_id=`(aws ssm send-command --document-name ${aws_ssm_document.cloud_init_wait.arn} --instance-ids ${aws_instance.chef-server.id} --output text --query "Command.CommandId")`
    
    # From experience...that chef server init takes 10 min to init on a t3.medium - Now Using Packer - Leave this 
    # Block In, but do not loop over checks. `aws ssm wait command-executed` polls on a fixed interval of 5s for 20x 
    # if does not init in 100s, assume it's a lost cause! 
    if ! aws ssm wait command-executed --command-id $command_id --instance-id ${aws_instance.chef-server.id}; then

      aws ssm get-command-invocation \
        --command-id $command_id \
        --instance-id ${aws_instance.chef-server.id} \
        --query StandardOutputContent
      
      aws ssm get-command-invocation \
        --command-id $command_id \
        --instance-id ${aws_instance.chef-server.id} \
        --query StandardErrorContent
      
      # [TODO][WARN] Kill the Instance If UserData Can't Get Brought Up - Keeps tf state Clean
      # This is pretty ugly, but if cloud init hangs or fails it taints the TF state file
      aws ec2 terminate-instances \
        --instance-ids ${aws_instance.chef-server.id}

      exit 1;
    fi;

    EOF
  }

  triggers = {
    cluster_instance_ids = aws_instance.chef-server.id
  }

}

data "aws_ami" "ubuntu-chef-server" {
  most_recent = true

  filter {
    name   = "name"
    values = [
      "ubuntu-*-chef-server-core-*"
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
resource "aws_instance" "chef-server" {

  # Basic Config - Use t3.medium running Ubuntu:20.04 w. VCPU + 4GB Memory + Configurable Storage (20GB)
  # Should be fine for our very basic Chef server deployment...
  ami           = data.aws_ami.ubuntu-chef-server.image_id
  instance_type = "t3.medium"
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
    aws_security_group.allow_deployer_http_sg.id
  ]

  # Storage
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    tags = {
      Name   = "Chef Server - Root Volume"
      Module = "Chef Server - Core Networking"
    }
  }

  # User Data
  # See `build_chef_server.sh` for details, builds a Chef Server for Ubuntu 20.04 w. all deps 
  user_data            = data.template_file.chef-infra-server-userdata.rendered
  iam_instance_profile = aws_iam_instance_profile.chef_server_profile.name

  # Monitoring & Metadata Mgmt 
  # [NOTE]: These are default options; Added for clarity
  monitoring = true
  metadata_options {
    http_endpoint = "enabled"
  }

  # Tags
  tags = {
    Name   = "Chef Server - Chef Infra Server - 01"
    Module = "Chef Server - Core Networking"
  }

}
