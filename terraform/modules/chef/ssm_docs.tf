
resource "aws_ssm_document" "cloud_init_wait" {

  name          = "cloud-init-wait"
  document_type = "Command"

  document_format = "YAML"
  content         = <<-DOC
    schemaVersion: '2.2'
    description: Wait for cloud init to finish
    mainSteps:
    - action: aws:runShellScript
      name: StopOnLinux
      precondition:
        StringEquals:
        - platformType
        - Linux
      inputs:
        runCommand:
        - cloud-init status --wait
    DOC
}

