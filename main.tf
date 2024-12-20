# Terraform provider configuration
terraform {
  required_providers {
    aws = {
      # Specify the source of the AWS provider
      source  = "hashicorp/aws"
      # Set the version constraint for the AWS provider
      version = "~> 5.0" 
    }
  }
}

# Configure the AWS provider
provider "aws" {
  # Set the AWS region for resource creation
  region     = var.region
  # Specify the AWS access key for authentication
  access_key = var.access_key
  # Specify the AWS secret key for authentication
  secret_key = var.secret_key
}

# Module for VPC and network resources
module "vpc" {
  # Source path for the VPC module
  source = "./modules/vpc"

  # Pass variables to the VPC module
  container_port     = var.container_port
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# Module for security groups and IAM roles
module "security" {
  # Source path for the security module
  source = "./modules/security"

  # Pass variables to the security module
  project_name   = var.project_name
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port
}

# Module for ECS resources
module "ecs" {
  # Source path for the ECS module
  source = "./modules/ecs"

  # Pass variables to the ECS module
  project_name                = var.project_name
  vpc_id                      = module.vpc.vpc_id
  subnet_ids                  = module.vpc.public_subnet_ids
  ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.security.ecs_task_role_arn
  ecs_tasks_security_group_id = module.security.ecs_tasks_security_group_id
  container_port              = var.container_port
  task_cpu                    = var.task_cpu
  task_memory                 = var.task_memory
  desired_count               = var.desired_count
  ecr_repository_url          = var.ecr_repository_url
  target_group_arn            = module.alb.target_group_arn
  region                      = var.region
  app_env_secret_arn          = module.security.app_secret_arn
}

# Module for Application Load Balancer
module "alb" {
  # Source path for the ALB module
  source = "./modules/alb"

  # Pass variables to the ALB module
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security.alb_security_group_id
  container_port    = var.container_port
  health_check_path = var.health_check_path
  certificate_arn   = module.security.acm_certificate_arn
}
