#
# Container Instance IAM resources
#
data "aws_iam_policy_document" "container_instance_ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "container_instance_ec2" {
  name               = "${var.environment}ContainerInstanceProfile"
  assume_role_policy = data.aws_iam_policy_document.container_instance_ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ec2_service_role" {
  role       = aws_iam_role.container_instance_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "container_instance" {
  name = aws_iam_role.container_instance_ec2.name
  role = aws_iam_role.container_instance_ec2.name
}

#
# Spot Fleet IAM resources
#
data "aws_iam_policy_document" "container_instance_spot_fleet_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "container_instance_spot_fleet" {
  name               = "fleet${var.environment}ServiceRole"
  assume_role_policy = data.aws_iam_policy_document.container_instance_spot_fleet_assume_role.json
}

resource "aws_iam_role_policy_attachment" "spot_fleet_policy" {
  role       = aws_iam_role.container_instance_spot_fleet.name
  policy_arn = var.aws_spot_fleet_service_role_policy_arn
}

#
# Batch IAM resources
#
data "aws_iam_policy_document" "container_instance_batch_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "container_instance_batch" {
  name               = "batchServiceRole"
  assume_role_policy = data.aws_iam_policy_document.container_instance_batch_assume_role.json
}

resource "aws_iam_role_policy_attachment" "batch_policy" {
  role       = aws_iam_role.container_instance_batch.name
  policy_arn = var.aws_batch_service_role_policy_arn
}

#
# VPC resources
#
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default" {
  count = length(var.aws_availability_zones)

  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = "Default subnet for ${var.aws_availability_zones[count.index]}"
  }
}

#
# Security group resources
#
resource "aws_security_group" "container_instance" {
  vpc_id = aws_default_vpc.default.id

  tags = {
    Name        = "sgContainerInstance"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "container_instance_ingress_ssh" {
  type             = "ingress"
  from_port        = 22
  to_port          = 22
  protocol         = "tcp"
  cidr_blocks      = var.external_access_cidr_blocks

  security_group_id = aws_security_group.container_instance.id
}

resource "aws_security_group_rule" "container_instance_egress_all" {
  type             = "egress"
  from_port        = 0
  to_port          = 65535
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.container_instance.id
}

#
# Batch resources
#
resource "aws_launch_template" "batch_cpu_container_instance" {
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 64
      volume_type = "gp2"
    }
  }

  user_data = filebase64("cloud-config/batch-container-instance.yml.tpl")
}

resource "aws_batch_compute_environment" "cpu" {
  depends_on = [aws_iam_role_policy_attachment.batch_policy]

  compute_environment_name = "batch${var.environment}CPUComputeEnvironment"
  type                     = "MANAGED"
  state                    = "ENABLED"
  service_role             = aws_iam_role.container_instance_batch.arn

  compute_resources {
    type           = "SPOT"
    bid_percentage = var.batch_cpu_ce_spot_fleet_bid_precentage
    ec2_key_pair   = var.aws_key_name
    image_id       = var.batch_cpu_ami_id

    min_vcpus     = var.batch_cpu_ce_min_vcpus
    desired_vcpus = var.batch_cpu_ce_desired_vcpus
    max_vcpus     = var.batch_cpu_ce_max_vcpus

    spot_iam_fleet_role = aws_iam_role.container_instance_spot_fleet.arn
    instance_role       = aws_iam_instance_profile.container_instance.arn

    instance_type = var.batch_cpu_ce_instance_types

    launch_template {
      launch_template_id = aws_launch_template.batch_cpu_container_instance.id
      version            = "$Latest"
    }

    security_group_ids = [
      aws_security_group.container_instance.id,
    ]

    subnets = aws_default_subnet.default[*].id

    tags = {
      Name               = "BatchWorker"
      ComputeEnvironment = "CPU"
      Project            = var.project
      Environment        = var.environment
    }
  }
}

resource "aws_batch_job_queue" "cpu" {
  name                 = "queue${var.environment}CPU"
  priority             = 1
  state                = "ENABLED"
  compute_environments = [aws_batch_compute_environment.cpu.arn]
}

resource "aws_batch_job_definition" "test_cpu" {
  name = "test_cpu_job_definition"
  type = "container"

  container_properties = file("job-definitions/test-cpu.json")
}

resource "aws_launch_template" "batch_gpu_container_instance" {
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 64
      volume_type = "gp2"
    }
  }
}

resource "aws_batch_compute_environment" "gpu" {
  depends_on = [aws_iam_role_policy_attachment.batch_policy]

  compute_environment_name = "batch${var.environment}GPUComputeEnvironment"
  type                     = "MANAGED"
  state                    = "ENABLED"
  service_role             = aws_iam_role.container_instance_batch.arn

  compute_resources {
    type           = "SPOT"
    bid_percentage = var.batch_gpu_ce_spot_fleet_bid_precentage
    ec2_key_pair   = var.aws_key_name
    image_id       = var.batch_gpu_ami_id

    min_vcpus     = var.batch_gpu_ce_min_vcpus
    desired_vcpus = var.batch_gpu_ce_desired_vcpus
    max_vcpus     = var.batch_gpu_ce_max_vcpus

    spot_iam_fleet_role = aws_iam_role.container_instance_spot_fleet.arn
    instance_role       = aws_iam_instance_profile.container_instance.arn

    instance_type = var.batch_gpu_ce_instance_types

    launch_template {
      launch_template_id = aws_launch_template.batch_gpu_container_instance.id
    }

    security_group_ids = [
      aws_security_group.container_instance.id,
    ]

    subnets = aws_default_subnet.default[*].id

    tags = {
      Name               = "BatchWorker"
      ComputeEnvironment = "GPU"
      Project            = var.project
      Environment        = var.environment
    }
  }
}

resource "aws_batch_job_queue" "gpu" {
  name                 = "queue${var.environment}GPU"
  priority             = 1
  state                = "ENABLED"
  compute_environments = [aws_batch_compute_environment.gpu.arn]
}

resource "aws_batch_job_definition" "test_gpu" {
  name = "test_gpu_job_definition"
  type = "container"

  container_properties = file("job-definitions/test-gpu.json")
}
