
# EC2 Instance that hosts the Chef Server

# Resource: https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file
data "template_file" "workstation-userdata" {
  template = filebase64("./../modules/chef/user_data/workstation_userdata.sh")
  depends_on = [
    null_resource.wait_for_chef_init
  ]
}

# Resource: https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep
resource "time_sleep" "wait_30_seconds_workstation" {
  create_duration = "30s"
  depends_on = [
    aws_instance.chef-workstation
  ]
}

# [CAREFUL W. PROVISIONERS!] Local Exec => Execute a SSM document From Local Machine
# which waits for cloud init to finish - blocks ASG from coming up before Workstation
# or Workstation from coming up before server
# Suggestion From: https://rpadovani.com/terraform-cloudinit
resource "null_resource" "wait_for_workstation_init" {

  provisioner "local-exec" {
    command = <<-EOF
    set -x -Ee -o pipefail;

    echo `(cat /etc/*-release)`

    export AWS_DEFAULT_REGION=${var.default_region}

    apt-get update && apt-get install -y jq awscli

    command_id=`(aws ssm send-command --document-name ${aws_ssm_document.cloud_init_wait.arn} --instance-ids ${aws_instance.chef-workstation.id} --output text --query "Command.CommandId")`
    
    for i in {0..5}
    do
      if ! aws ssm wait command-executed --command-id $command_id --instance-id ${aws_instance.chef-workstation.id}; then
        echo "SSM Call #$i - Still Waiting on Workstation Init"
        aws ssm get-command-invocation \
          --command-id $command_id \
          --instance-id ${aws_instance.chef-workstation.id} \
          --query StandardOutputContent
      fi;
    done

    # Last Attempt!
    if ! aws ssm wait command-executed --command-id $command_id --instance-id ${aws_instance.chef-workstation.id}; then

      aws ssm get-command-invocation \
        --command-id $command_id \
        --instance-id ${aws_instance.chef-workstation.id} \
        --query StandardOutputContent
      
      aws ssm get-command-invocation \
        --command-id $command_id \
        --instance-id ${aws_instance.chef-workstation.id} \
        --query StandardErrorContent
      
      # Kill the Instance If UserData Can't Get Brought Up - Keeps tf state Clean
      aws ec2 terminate-instances --instance-ids ${aws_instance.chef-workstation.id}
      exit 1
    fi;

    EOF
  }

  # Instance MUST show as available; w.o wait get pending instance errors!
  depends_on = [
    aws_instance.chef-workstation,
    time_sleep.wait_30_seconds_workstation
  ]

  # Pre-emptive commands => On Instance ID Change
  triggers = {
    cluster_instance_ids = aws_instance.chef-workstation.id
  }

}

# Need an instance that can be used as the Chef Server
# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "chef-workstation" {

  # Basic Config - Use t3.medium running Ubuntu:20.04 w. VCPU + 4GB Memory + Configurable Storage (20GB)
  # Should be fine for our very basic Chef server deployment...
  ami           = "ami-09e67e426f25ce0d7"
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