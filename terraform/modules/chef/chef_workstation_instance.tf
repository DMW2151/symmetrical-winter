
# EC2 Instance that hosts the Chef Server

# Resource: https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file
data "template_file" "workstation-userdata" {
  template = filebase64("./../modules/chef/user_data/workstation_userdata.sh")
  depends_on = [
    null_resource.wait_for_chef_init
  ]
}

# [CAREFUL W. PROVISIONERS!] Local Exec => Execute a SSM document From Local Machine
# which waits for cloud init to finish - blocks ASG from coming up before Workstation
# or Workstation from coming up before server
# Suggestion From: https://rpadovani.com/terraform-cloudinit
resource "null_resource" "wait_for_workstation_init" {

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOF
    set -x;

    # Small Buffer to Ensure Instance is Up - Could be a Null Resource
    sleep 30;
    export isalpine=$(uname -a | grep -iE alpine)

    uname -a

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
    
    command_id=`(aws ssm send-command --document-name ${aws_ssm_document.cloud_init_wait.arn} --instance-ids ${aws_instance.chef-workstation.id} --output text --query "Command.CommandId")`
    
    # From experience...that chef server init takes 10 min to init on a t3.medium - Now Using Packer - Leave this 
    # Block In, but do not loop over checks. `aws ssm wait command-executed` polls on a fixed interval of 5s for 20x 
    # if does not init in 100s, assume it's a lost cause!
    if ! aws ssm wait command-executed --command-id $command_id --instance-id ${aws_instance.chef-workstation.id}; then

      aws ssm get-command-invocation \
        --command-id $command_id \
        --instance-id ${aws_instance.chef-workstation.id} \
        --query StandardOutputContent
      
      aws ssm get-command-invocation \
        --command-id $command_id \
        --instance-id ${aws_instance.chef-workstation.id} \
        --query StandardErrorContent
      
      # [TODO][WARN] Kill the Instance If UserData Can't Get Brought Up - Keeps tf state Clean
      # This is pretty ugly, but if cloud init hangs or fails it taints the TF state file...
      # aws ec2 terminate-instances \
      #  --instance-ids ${aws_instance.chef-workstation.id}
      exit 1
    fi;

    EOF
  }

  # Pre-emptive commands => On Instance ID Change
  triggers = {
    cluster_instance_ids = aws_instance.chef-workstation.id
  }

}
data "aws_ami" "ubuntu-chef-workstation" {
  most_recent = true

  filter {
    name   = "name"
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
    null_resource.wait_for_chef_init
  ]

  # Tags
  tags = {
    Name   = "Chef - Workstation"
    Module = "Chef Server - Core Networking"
  }

}