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
  default     = "descier-app"
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

variable "subnet_a_id" {
  description = "ID of subnet A"
  type        = string
}

variable "subnet_b_id" {
  description = "ID of subnet B"
  type        = string
}

variable "subnet_c_id" {
  description = "ID of subnet C"
  type        = string
}

variable "container_port" {
  description = "Port on which the container is listening"
  type        = number
  default     = 3000
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
  default     = "/home"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for the subnets"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
}

variable "app_env_secret_arn" {
  description = "ARN of the environment file"
  type        = string
}
