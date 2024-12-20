# Create an Application Load Balancer (ALB)
resource "aws_lb" "main" {
  # Name of the ALB, using the project name as a prefix
  name               = "${var.project_name}-alb"
  
  # Set to false for an internet-facing ALB
  internal           = false
  
  # Specify the load balancer type as "application"
  load_balancer_type = "application"
  
  # Assign the security group to the ALB
  security_groups    = [var.security_group_id]
  
  # Specify the subnets where the ALB will be deployed
  subnets            = var.subnet_ids
  
  # Set the idle timeout for the ALB (in seconds)
  idle_timeout       = 120

  # Disable deletion protection for easier management in non-production environments
  enable_deletion_protection = false

  # Add tags to the ALB resource
  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Create an ALB target group for the ECS tasks
resource "aws_lb_target_group" "main" {
  # Name of the target group, using the project name as a prefix
  name        = "${var.project_name}-tg"
  
  # Port on which the targets receive traffic
  port        = var.container_port
  
  # Protocol used to route traffic to the targets
  protocol    = "HTTP"
  
  # ID of the VPC in which to create the target group
  vpc_id      = var.vpc_id
  
  # Type of target to register with the target group (IP addresses for Fargate)
  target_type = "ip"

  # Configure health checks for the target group
  health_check {
    path                = var.health_check_path
    interval            = 60
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }

  # Add tags to the target group resource
  tags = {
    Name = "${var.project_name}-tg"
  }
}

# Create an HTTP listener for the ALB
resource "aws_lb_listener" "http_listener" {
  # ARN of the load balancer to which this listener is attached
  load_balancer_arn = aws_lb.main.arn
  
  # Port on which the listener listens for incoming traffic
  port              = 80
  
  # Protocol for connections from clients to the listener
  protocol          = "HTTP"

  # Configure the default action for the listener (redirect to HTTPS)
  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

# Create an HTTPS listener for the ALB
resource "aws_lb_listener" "https" {
  # ARN of the load balancer to which this listener is attached
  load_balancer_arn = aws_lb.main.arn
  
  # Port on which the listener listens for incoming traffic
  port              = 443
  
  # Protocol for connections from clients to the listener
  protocol          = "HTTPS"
  
  # Security policy that defines which SSL/TLS protocols and ciphers are supported
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  
  # ARN of the default SSL server certificate to use
  certificate_arn   = var.certificate_arn

  # Configure the default action for the listener (forward to target group)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Attach an additional certificate to the HTTPS listener
resource "aws_lb_listener_certificate" "https" {
  # ARN of the listener to which to attach the certificate
  listener_arn    = aws_lb_listener.https.arn
  
  # ARN of the certificate to attach
  certificate_arn = var.certificate_arn
}
