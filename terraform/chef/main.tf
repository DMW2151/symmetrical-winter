# Deploy a Chef Infra Server onto AWS w. Terraform following the recommendations given here:
#   - https://docs.chef.io/server/install_server/

terraform {

  backend "s3" {
    bucket = "dmw2151-chef" # [PREREQ]: Requires that this Bucket Already Exists...
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

# [TODO] Replace Hard Coded Values with Variables...
provider "aws" {
  region  = "us-east-1"
  profile = "dmw2151"
}

# [TODO][NOTE][DEV] IP address of the terraform user - assumes deployment from local env.
data "http" "deployerip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_caller_identity" "current" {}

module "chef" {
  source                      = "../modules/chef"
  deployer_ip                 = "${chomp(data.http.deployerip.body)}/32"
  aws_account_id              = data.aws_caller_identity.current.account_id
  default_region              = "us-east-1"
  default_availability_zone   = "us-east-1f"
  secondary_availability_zone = "us-east-1d"
}