data "local_file" "env_json" {
  filename = "${path.module}/../../.env.app.json"
}

# Security group for the Application Load Balancer (ALB)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Ingress rule for HTTP
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Ingress rule for HTTPS
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Egress rule for all traffic
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # All protocols
}

# IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]

  tags = {
    Name = "${var.project_name}-ecs-task-execution-role"
  }
}

# IAM role for ECS task
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }
}

# Criação do segredo no AWS Secrets Manager
resource "aws_secretsmanager_secret" "desci_app_develop" {
  name        = "${var.project_name}-develop"
  description = "Variáveis de ambiente para a aplicação ${var.project_name}"

  tags = {
    Name = "${var.project_name}-desci-app-dev-env"
  }
}

# Definição da versão do segredo (valores sensíveis)
resource "aws_secretsmanager_secret_version" "desci_app_dev_env_version" {
  secret_id     = aws_secretsmanager_secret.desci_app_develop.id
  secret_string = data.local_file.env_json.content
}

# Documento de política para permitir acesso aos papéis do ECS
data "aws_iam_policy_document" "desci_app_dev_env_policy" {
  statement {
    sid    = "AllowECSRolesAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [
        aws_iam_role.ecs_task_execution.arn,
        aws_iam_role.ecs_task.arn
      ]
    }

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      aws_secretsmanager_secret.desci_app_develop.arn
    ]
  }
}

# Anexar a política de recursos ao segredo
resource "aws_secretsmanager_secret_policy" "desci_app_dev_env_policy" {
  secret_arn = aws_secretsmanager_secret.desci_app_develop.arn
  policy     = data.aws_iam_policy_document.desci_app_dev_env_policy.json
}