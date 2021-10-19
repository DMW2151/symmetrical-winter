# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace
resource "aws_service_discovery_private_dns_namespace" "chef" {
  name        = "chef.local"
  description = "chef service - includes main server"
  vpc         = aws_vpc.infra-vpc
}

# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service
resource "aws_service_discovery_service" "chef_svc" {
  name = "chef_svc"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.chef.id

    dns_records {
      ttl  = 300
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_instance
resource "aws_service_discovery_instance" "chef_svc_master" {
  instance_id = "chef_svc_master"
  service_id  = aws_service_discovery_service.chef_svc.id

  attributes = {
    AWS_EC2_INSTANCE_ID = aws_instance.chef-server.id
  }
}