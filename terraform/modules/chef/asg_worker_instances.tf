# Configures Autoscaling Group (ASG) Workers for the Core JupyterHub Service

# Resource: https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file
data "template_file" "worker-userdata" {
  template = filebase64("./../modules/chef/user_data/worker_userdata.sh")
}

# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration
resource "aws_launch_configuration" "chef-workers" {

  # Basic
  image_id                    = "ami-09e67e426f25ce0d7"
  instance_type               = "t3.small"
  spot_price                  = "0.04"

  # Security
  security_groups = [
    aws_security_group.allow_vpc_traffic_sg.id,
    aws_security_group.allow_deployer_sg.id,
  ]
  key_name                    = "public-jump-1"
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.chef_server_profile.name

  # Lifecycle Management
  lifecycle {
    create_before_destroy = true
  }

  # Instance Intialization
  user_data                   = data.template_file.worker-userdata.rendered

  depends_on = [
    null_resource.wait_for_workstation_init
  ]
}

# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "chef-workers" {

  # Basic
  name                 = "jupyter-workers-asg"
  launch_configuration = aws_launch_configuration.chef-workers.name

  # Scaling Rules => Min, Max, and Desired Instances - Infrastructure Cap
  min_size         = 1
  desired_capacity = 1
  max_size         = 2

  # Health
  health_check_grace_period = 300
  health_check_type         = "EC2"

  # Security + Networking
  vpc_zone_identifier = [
    aws_subnet.default_subnet.id
  ]

  # Tags - Defined as Single Blocks for `aws_autoscaling_group`
  tag {
    key                 = "Name"
    value               = "Chef - Juyter Hub Worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Launched By"
    value               = "Chef ASG"
    propagate_at_launch = true
  }

}