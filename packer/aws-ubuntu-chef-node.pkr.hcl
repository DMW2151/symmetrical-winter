// Build Chef Server + Chef Client (Workstation and ASG Nodes) Images
packer {

  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }

}

// Build Variables...
variable "src_ami_owner" {
  type        = string
  description = "AWS ID of Owner of source instance, defaults to Canonical's ID"
  default     = "099720109477"
}

variable "ubuntu_version" {
  type        = string
  description = "Variable for AWS ID of Owner of source instance, defaults to Canonical's ID"
  default     = "20.04"
}

variable "chef_version" {
  type        = string
  description = "Variable for AWS ID of Owner of source instance, defaults to Canonical's ID"
  default     = "14.10.23"
}

variable "chef_workstation_version" {
  type        = string
  description = "Variable for AWS ID of Owner of source instance, defaults to Canonical's ID"
  default     = "0.2.43"
}

variable "aws_profile" {
  type        = string
  description = "Variable for AWS ID of Owner of source instance, defaults to Canonical's ID"
  default     = "dmw2151"
}

variable "aws_region" {
  type        = string
  description = "Variable for AWS ID of Owner of source instance, defaults to Canonical's ID"
  default     = "us-east-1"
}


// Source  - Client Nodes
source "amazon-ebs" "ubuntu-chef-nodes" {

  ami_name      = "ubuntu-${var.ubuntu_version}-chef-client-${var.chef_version}"
  ssh_username  = "ubuntu"
  instance_type = "t3.medium"
  region        = "${var.aws_region}"
  profile       = "${var.aws_profile}"

  source_ami_filter {

    // Start with Recent Ubuntu 20.04 EBS Instance
    filters = {
      name                = "ubuntu/images/*ubuntu-*-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }

    most_recent = true
    owners      = ["${var.src_ami_owner}"]
  }

  tags = {
    OS_Version = "Ubuntu"
    Release    = "Latest"
    Build Repo = ""
    Build File = ""
  }

}


// Builds...

// Chef Nodes Build
//
// This build removes the need to do an unattended install and registration of a new Chef node. 
// The below registers the node, replicating what `knife bootstrap` does but from the 
// node -> server; not server -> node
//
// See Reference: https://docs.chef.io/install_bootstrap/#unattended-installs
//
build {
  name        = "ubuntu-chef-nodes"
  description = "This build creates images for Ubuntu w. Chef Server and Chef Manage"

  sources = [
    "source.amazon-ebs.ubuntu-chef-nodes"
  ]

  provisioner "shell" {

    // Create logging locations etc...
    inline = [
      "#! /bin/bash -e -x;",
      "sudo mkdir -p /etc/chef && sudo mkdir -p /var/lib/chef && sudo mkdir -p /var/log/chef",
      "sudo chown -R ubuntu /etc/chef/ && sudo chown -R ubuntu /var/log/chef",
      "sudo wget https://omnitruck.chef.io/install.sh -O /etc/chef/install.sh",
      "sudo bash /etc/chef/install.sh"
    ]
  }

}
