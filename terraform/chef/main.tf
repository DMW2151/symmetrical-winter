# Deploy a Chef Infra Server onto AWS w. Terraform following the recommendations given here:
#   - https://docs.chef.io/server/install_server/

# Change `bucket`, `region`, `profile` as needed, note that module expects `${ADMIN_USERNAME}-chef` as a bucket
# for initializing the containers!

terraform {

  backend "s3" {
    bucket = "dmw2151-chef"
    key    = "state_files/chef-stack.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.61.0"
    }
  }
  required_version = ">= 1.0.3"

}

provider "aws" {
  region  = "us-east-1"
  profile = "dmw2151"
}


data "aws_caller_identity" "current" {}

module "chef" {
  source                      = "../modules/chef"
  deployer_ip                 = "${var.deployer_ip}"
  aws_account_id              = data.aws_caller_identity.current.account_id
  default_region              = "us-east-1"
  default_availability_zone   = "us-east-1f"
  secondary_availability_zone = "us-east-1d"
  target_domain               = "maphub.dev"
}

output "workstation_ip" {
  value = module.chef.chef-workstation-ip
}

output "ssh_group_id" {
  value = module.chef.ssh_group_id
}

