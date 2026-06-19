locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===== LAUNCH TEMPLATE =====
resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-lt(template)"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.app_security_group_id]

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-EOF
        #!/bin/bash
        yum update -y

        yum install -y httpd

        systemctl start httpd
        systemctl enable httpd

        echo "<h1>Three-Tier Architecture Auto Scaling Server $(hostname)</h1>" > /var/www/html/index.html
        EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${local.name_prefix}-app-instance"
      Environment = var.environment
      Project     = var.project_name
    }

  }

  tags = {
    Name = "${local.name_prefix}-launch-template"
  }
}

# ===== AUTO SCALING GROUP =====
resource "aws_autoscaling_group" "app" {
  name = "${local.name_prefix}-asg"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = var.app_subnet_ids

  target_group_arns = [var.target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id = aws_launch_template.app.id
    # Pinned to the version that was actually applied, instead of "$Latest",
    # so a new Launch Template revision doesn't silently roll out to the ASG
    # outside of a controlled CI/CD deploy.
    version = aws_launch_template.app.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}