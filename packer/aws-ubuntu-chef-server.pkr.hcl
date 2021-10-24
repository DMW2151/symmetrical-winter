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


// Source  - Chef Server
source "amazon-ebs" "ubuntu-chef-server" {

  ami_name      = "ubuntu-${var.ubuntu_version}-chef-server-core-${var.chef_version}"
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
  }

}

// Chef Server Build
//
// This build bakes the main Chef Server AMI - Creates an AMI with the specified Chef Server Version 
// on the specified Ubuntu Version. NOTE: Build is for X86_64 only.
//
build {
  name        = "ubuntu-chef-server"
  description = "This build creates images for Ubuntu w. Chef Server and Chef Manage"

  sources = [
    "source.amazon-ebs.ubuntu-chef-server"
  ]

  provisioner "shell" {

    inline = [
      "#! /bin/bash -e -x;",
      "wget https://packages.chef.io/files/stable/chef-server/${var.chef_version}/ubuntu/${var.ubuntu_version}/chef-server-core_${var.chef_version}-1_amd64.deb",
      "sudo dpkg -i chef-server-core_${var.chef_version}-1_amd64.deb",
      "sudo rm chef-server-core_${var.chef_version}-1_amd64.deb",
      "sudo chef-server-ctl reconfigure --chef-license=accept",
      "sudo chef-server-ctl install chef-manage",
      "sudo chef-server-ctl reconfigure",
      "sudo chef-manage-ctl reconfigure",
      "sudo rm -f /var/opt/opscode/nginx/ca/*"
    ]
  }
}