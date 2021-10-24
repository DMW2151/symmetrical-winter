// Build Chef Server + Chef Client (Workstation and ASG Nodes) Images
packer {

  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }

}

// Build Locals...
locals {  
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
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

// Source - Workstation Nodes
source "amazon-ebs" "ubuntu-chef-workstation" {

  ami_name      = "ubuntu-${var.ubuntu_version}-chef-client-core-${var.chef_version}-${local.timestamp}"
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


// Builds...


// Chef Workstation Build
// 
// This build takes 
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
      "wget https://packages.chef.io/files/stable/chef-workstation/${var.chef_workstation_version}/ubuntu/${var.ubuntu_version}/chef-workstation_${var.chef_workstation_version}-1_amd64.deb",
      "sudo dpkg -i chef-workstation_${var.chef_workstation_version}-1_amd64.deb",
      "rm chef-workstation_${var.chef_workstation_version}-1_amd64.deb"
    ]
  }
}