# Create an IAM Instance Role for the Chef server

# Assume Role Policy - Default - Exists on AWS already (Assume this is true...)
# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Policy allows for reading parameters from SSM: 
# [TODO]/[WARN]: Can/should change to secrets mangager for a production deployment
# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "ssm_rw" {

  name = "ssm_param_rw"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:CreateDocument",
          "ssm:PutParameter",
          "ssm:DeleteDocument",
          "ssm:DescribeDocument",
          "ssm:DescribeDocumentParameters",
          "ssm:DescribeDocumentPermission",
          "ssm:GetDocument",
          "ssm:ListDocuments",
          "ssm:SendCommand",
          "ssm:UpdateDocument",
          "ssm:UpdateDocumentDefaultVersion",
          "ssm:UpdateDocumentMetadata"
        ],
        "Resource" : "*"
      }
    ]
  })
}


resource "aws_iam_policy" "acm_reader" {

  name = "acm_param_reader"

  // TODO - Tighten!!
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "acm:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

data "aws_iam_policy" "s3_full" {
  name = "AmazonS3FullAccess"
}


data "aws_iam_policy" "svc_discovery_read" {
  name = "AWSCloudMapReadOnlyAccess"
}


data "aws_iam_policy" "ssm_mgmt" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ecr_read_only_plus" {
  name = "AmazonElasticContainerRegistryPublicReadOnly"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetRepositoryPolicy",
                "sts:GetServiceBearerToken",
                "ecr:BatchGetImage",
                "ecr:GetDownloadUrlForLayer"
            ],
            "Resource": "*"
        }
    ]
 })

}


# Create an IAM role for The Chef Server w. SSM reader attached!
# Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
# [TODO]: This instnce profile is being used for more than just Chef; It should be paired down
# and split into roles for the ASG nodes etc...in general though, access to S3, SSM, and CloudMap is
# essential...
resource "aws_iam_role" "chef_server_profile" {
  name               = "chef_server_role"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
  managed_policy_arns = [
    aws_iam_policy.ssm_rw.arn,
    aws_iam_policy.acm_reader.arn,
    aws_iam_policy.ecr_read_only_plus.arn,
    data.aws_iam_policy.s3_full.arn,
    data.aws_iam_policy.ssm_mgmt.arn,
    data.aws_iam_policy.svc_discovery_read.arn
  ]
}

resource "aws_iam_instance_profile" "chef_server_profile" {
  name = "chef_server_instance_profile"
  role = aws_iam_role.chef_server_profile.name
}