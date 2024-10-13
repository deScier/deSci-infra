# Terraform provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.71.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# Module for VPC and network resources
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# Module for security groups and IAM roles
module "security" {
  source = "./modules/security"

  project_name   = var.project_name
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port
}

# Module for ECS resources
module "ecs" {
  source = "./modules/ecs"

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
}

# Module for Application Load Balancer
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security.alb_security_group_id
  container_port    = var.container_port
  health_check_path = var.health_check_path
}