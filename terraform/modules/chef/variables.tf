variable "deployer_ip" {
  description = "[DEV] IP Address (CIDR) of the deployer"
  type        = string
  sensitive   = true
}

variable "aws_account_id" {
  description = "[DEV] Account ID of the deployer"
  type        = string
  sensitive   = true
}

variable "default_region" {
  description = "Default AWS Region in following format: `us-east-1`"
  type        = string
}


variable "default_availability_zone" {
  description = "Default AWS Availability Zone, must be within `default_region`, e.g. `us-east-1` and `us-east-1f`"
  type        = string
}

variable "secondary_availability_zone" {
  description = "Secondary AWS Availability Zone, must be within `default_region`, e.g. `us-east-1` and `us-east-1f`"
  type        = string
}

