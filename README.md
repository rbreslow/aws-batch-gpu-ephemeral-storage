# aws-batch-gpu-ephemeral-storage

The goal of this repository is to flex:

- AWS Batch on Terraform 0.12
- [`aws_launch_template`](https://www.terraform.io/docs/providers/aws/r/launch_template.html)
    - Initializing unformatted [instance store](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html) volumes
    - Configuring block device mappings for AWS Batch without building an AMI
- [Amazon ECS GPU-optimized AMI](https://docs.aws.amazon.com/batch/latest/userguide/batch-gpu-ami.html) vs. building our own AMI

💪