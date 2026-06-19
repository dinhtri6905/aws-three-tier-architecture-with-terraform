variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Deploy Environment"
  type        = string
}

variable "aws_region" {
  description = "AWS Region — used in Dashboard links"
  type        = string
}

# ============================================================
# SNS
# ============================================================
variable "sns_email" {
  description = "Email address for alerts. Leave empty to disable."
  type        = string
  default     = ""
}

# ============================================================
# APP TIER — Auto Scaling Group
# ============================================================
variable "autoscaling_group_name" {
  description = "ASG name — output from `autoscaling` module"
  type        = string
}

variable "asg_cpu_high_threshold" {
  description = "CPU high threshold (%)"
  type        = number
}

variable "asg_cpu_low_threshold" {
  description = "CPU low threshold (%)"
  type        = number
}

# ============================================================
# DATA TIER — RDS
# ============================================================
variable "rds_instance_id" {
  description = "RDS instance ID — output from `rds` module"
  type        = string
}

variable "rds_cpu_high_threshold" {
  description = "RDS CPU threshold (%)"
  type        = number
}

variable "rds_free_storage_threshold" {
  description = "Free storage threshold (bytes)"
  type        = number
}

variable "rds_connections_threshold" {
  description = "Max concurrent connections threshold"
  type        = number
}

# ============================================================
# WEB TIER — ALB
# ============================================================
variable "alb_arn_suffix" {
  description = "ALB ARN suffix — output from `alb` module"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target Group ARN suffix — output from `alb` module"
  type        = string
}

variable "alb_5xx_threshold" {
  description = "Number of 5xx errors per minute before alarm"
  type        = number
  default     = 10
}

variable "alb_response_time_threshold" {
  description = "Maximum response time (seconds)"
  type        = number
}

# ============================================================
# LOG GROUPS
# ============================================================
variable "log_retention_days" {
  description = "Number of days to retain logs. Valid values: 1, 3, 5, 7, 14, 30, 60, 90..."
  type        = number
}

