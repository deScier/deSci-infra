data "local_file" "env_json" {
  filename = "${path.module}/../../.env.app.json"
}

# Grupo de segurança para o Application Load Balancer (ALB)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Create a target group for the ECS tasks
resource "aws_lb_target_group" "app_target_group" {
  name     = "${var.project_name}-target-group"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Papel IAM para a tarefa ECS
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_s3_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_cloudwatch_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Papel IAM para execução da tarefa ECS
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

# Grupo de segurança para tarefas ECS
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound traffic to container port"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }
}

# Cria um segredo no AWS Secrets Manager
resource "aws_secretsmanager_secret" "desci_app_develop" {
  name        = "${var.project_name}-develop-environment"
  description = "Environment variables for ${var.project_name} application"

  tags = {
    Name = "${var.project_name}-develop-environment"
  }
}

# Define a versão do segredo
resource "aws_secretsmanager_secret_version" "desci_app_dev_env_version" {
  secret_id     = aws_secretsmanager_secret.desci_app_develop.id
  secret_string = data.local_file.env_json.content
}

# Documento de política para permitir acesso aos papéis ECS
data "aws_iam_policy_document" "desci_app_dev_env_policy" {
  statement {
    sid    = "AllowECSRolesAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [
        aws_iam_role.ecs_task_execution.arn,
        aws_iam_role.ecs_task_role.arn
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

# Anexa a política de recurso ao segredo
resource "aws_secretsmanager_secret_policy" "desci_app_dev_env_policy" {
  secret_arn = aws_secretsmanager_secret.desci_app_develop.arn
  policy     = data.aws_iam_policy_document.desci_app_dev_env_policy.json
}
