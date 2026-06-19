locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===== IAM ROLE FOR EC2 / ASG APPLICATION INSTANCES =====
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_instance" {
  name               = "${local.name_prefix}-app-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "${local.name_prefix}-app-instance-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Allows access via AWS Systems Manager Session Manager instead of SSH
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allows instances to push custom logs/metrics via the CloudWatch Agent
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "app_instance" {
  name = "${local.name_prefix}-app-instance-profile"
  role = aws_iam_role.app_instance.name

  tags = {
    Name        = "${local.name_prefix}-app-instance-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}
