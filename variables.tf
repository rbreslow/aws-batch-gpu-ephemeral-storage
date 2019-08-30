variable "project" {
  default = "aws-batch-gpu-ephemeral-storage"
}

variable "environment" {
  default = "Staging"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "aws_spot_fleet_service_role_policy_arn" {
  default = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

variable "aws_batch_service_role_policy_arn" {
  default = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

variable "aws_key_name" {
}

variable "external_access_cidr_blocks" {
    type = list(string)
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html#al2ami
variable "batch_cpu_ami_id" {
}

variable "batch_cpu_ce_min_vcpus" {
}

variable "batch_cpu_ce_desired_vcpus" {
}

variable "batch_cpu_ce_max_vcpus" {
}

variable "batch_cpu_ce_instance_types" {
  type = list(string)
}

variable "batch_cpu_ce_spot_fleet_bid_precentage" {
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html#amazon-linux-2-(gpu)
variable "batch_gpu_ami_id" {
}

variable "batch_gpu_ce_min_vcpus" {
}

variable "batch_gpu_ce_desired_vcpus" {
}

variable "batch_gpu_ce_max_vcpus" {
}

variable "batch_gpu_ce_instance_types" {
  type = list(string)
}

variable "batch_gpu_ce_spot_fleet_bid_precentage" {
}

