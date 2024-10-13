# variables.tf

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "access_key" {
  description = "AWS access key"
  type        = string
}

variable "secret_key" {
  description = "AWS secret key"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "container_port" {
  description = "Port on which the container is listening"
  type        = number
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = string
}

variable "task_memory" {
  description = "Memory for the task in MiB"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "health_check_path" {
  description = "Path for ALB health check"
  type        = string
  default     = "/"
}