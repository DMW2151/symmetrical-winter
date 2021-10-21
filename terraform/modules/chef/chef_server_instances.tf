# Configures core EC2 Instance that hosts the Chef Server

# Resource: https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep
resource "time_sleep" "wait_30_seconds_server" {
  create_duration = "30s"

  depends_on = [
    aws_instance.chef-server
  ]
}

resource "null_resource" "wait_for_chef_init" {

  # Suggestion: https://rpadovani.com/terraform-cloudinit
  provisioner "local-exec" {

    interpreter = ["/bin/bash", "-c"]

    command = <<-EOF
    set -x -Ee -o pipefail;

    export AWS_DEFAULT_REGION=${var.default_region}

    sudo apt-get update &&\
    sudo apt-get install -y jq awscli

    export command_id=`(aws ssm send-command --document-name ${aws_ssm_document.cloud_init_wait.arn} --instance-ids ${aws_instance.chef-server.id} --output text --query "Command.CommandId")`
    
    # [REQ]: This needs awscli 1.19+; For Reference: (aws-cli/1.20.42 Python/3.7.3 botocore/1.21.42)
    # Hamfisted and Inelegant - AFAIK `aws ssm wait command-executed` polls on a
    # fixed interval of 5s for 20x; no way to extend beyond 100s interval
    
    # From experience...that chef server init takes 5+ min always, give up to 100 * 10 == 20 min to init!
    for i in {0..10}
    do
      if ! aws ssm wait command-executed --command-id $command_id --instance-id ${aws_instance.chef-server.id}; then
        echo "SSM Call #$i - Still Waiting on Chef Init"
        aws ssm get-command-invocation \
          --command-id $command_id \
          --instance-id ${aws_instance.chef-server.id} \
          --query StandardOutputContent
      fi;
    done

    # Last Attempt!
    if ! aws ssm wait command-executed --command-id $command_id --instance-id ${aws_instance.chef-server.id}; then

      aws ssm get-command-invocation \
        --command-id $command_id \
        --instance-id ${aws_instance.chef-server.id} \
        --query StandardOutputContent
      
      aws ssm get-command-invocation \
        --command-id $command_id \
        --instance-id ${aws_instance.chef-server.id} \
        --query StandardErrorContent
      
      # Kill the Instance If UserData Can't Get Brought Up - Keeps tf state Clean
      aws ec2 terminate-instances --instance-ids ${aws_instance.chef-server.id}
      exit 1;
    fi;

    EOF
  }

  depends_on = [
    time_sleep.wait_30_seconds_server
  ]

  triggers = {
    cluster_instance_ids = aws_instance.chef-server.id
  }

}

# Need an instance that can be used as the Chef Server
# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "chef-server" {

  # Basic Config - Use t3.medium running Ubuntu:20.04 w. VCPU + 4GB Memory + Configurable Storage (20GB)
  # Should be fine for our very basic Chef server deployment...
  ami           = "ami-09e67e426f25ce0d7"
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
    delete_on_termination = false
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

# Resource: https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file
data "template_file" "chef-infra-server-userdata" {
  template = filebase64("./../modules/chef/user_data/build_chef_server.sh")
  vars = {
    aws_default_region = "${var.default_region}"
  }
}
