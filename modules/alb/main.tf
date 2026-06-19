locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===== APPLICATION LOAD BALANCER =====
resource "aws_lb" "main" {
  #checkov:skip=CKV_AWS_150: Deletion protection disabled for lab environment
  #checkov:skip=CKV2_AWS_28: AWS WAF not required for lab environment
  #checkov:skip=CKV_AWS_91: ALB access logging disabled for lab environment

  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.alb_security_group_id]
  subnets         = var.public_subnet_ids

  drop_invalid_header_fields = true # Check: CKV_AWS_131: "Ensure that ALB drops HTTP headers"

  # access_logs {
  #   bucket  = var.alb_logs_id
  #   prefix  = "alb"
  #   enabled = true
  # }

  enable_deletion_protection = false

  tags = {
    Name        = "${local.name_prefix}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ===== TARGET GROUP =====
resource "aws_lb_target_group" "app" {
  #checkov:skip=CKV_AWS_378: Backend communication uses HTTP in lab environment

  name     = "${local.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "${local.name_prefix}-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ===== HTTP LISTENER =====
# When an ACM certificate is supplied (var.certificate_arn != ""), HTTP traffic
# is redirected to HTTPS instead of being forwarded directly to the Target Group.
# resource "aws_lb_listener" "http" {
#   #checkov:skip=CKV_AWS_2: Listener protocol depends on var.certificate_arn; redirects to HTTPS when a certificate is supplied
#   #checkov:skip=CKV_AWS_103: Listener protocol depends on var.certificate_arn; redirects to HTTPS when a certificate is supplied

#   load_balancer_arn = aws_lb.main.arn

#   port     = 80
#   protocol = "HTTP"

#   dynamic "default_action" {
#     for_each = var.certificate_arn != "" ? [1] : []
#     content {
#       type = "redirect"

#       redirect {
#         port        = "443"
#         protocol    = "HTTPS"
#         status_code = "HTTP_301"
#       }
#     }
#   }

#   dynamic "default_action" {
#     for_each = var.certificate_arn == "" ? [1] : []
#     content {
#       type             = "forward"
#       target_group_arn = aws_lb_target_group.app.arn
#     }
#   }

#   tags = {
#     Name = "${local.name_prefix}-http-listener"
#   }
# }

# # ===== HTTPS LISTENER =====
# # Only created when var.certificate_arn is set (e.g. production). Requires an
# # ACM certificate already issued/validated for the ALB's domain.
# resource "aws_lb_listener" "https" {
#   count = var.certificate_arn != "" ? 1 : 0

#   load_balancer_arn = aws_lb.main.arn

#   port            = 443
#   protocol        = "HTTPS"
#   ssl_policy      = var.ssl_policy
#   certificate_arn = var.certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }

#   tags = {
#     Name = "${local.name_prefix}-https-listener"
#   }
# }

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name = "${local.name_prefix}-http-listener"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn

  port            = 443
  protocol        = "HTTPS"
  ssl_policy      = var.ssl_policy
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "${local.name_prefix}-https-listener"
  }
}