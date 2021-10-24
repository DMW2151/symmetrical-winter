# Create the ECR Repos for the Hub Tasks:
#
#   - Analysis Container
#   - Hub Server Container
#

# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
resource "aws_ecr_repository" "jupyterhubserver" {
  # Basic
  name                 = "jupyterhubserver"
  image_tag_mutability = "MUTABLE"

  # Security constraints - Enable Snyk scan on push to repo
  image_scanning_configuration {
    scan_on_push = true
  }

  # Cannot be destroyed via terraform
  lifecycle {
    prevent_destroy = false
  }

}

resource "aws_ecr_repository" "geospatial" {
  # Basic
  name                 = "geospatial"
  image_tag_mutability = "MUTABLE"

  # Security constraints - Enable Snyk scan on push to repo
  image_scanning_configuration {
    scan_on_push = true
  }

  # Cannot be destroyed via terraform
  lifecycle {
    prevent_destroy = false
  }

}