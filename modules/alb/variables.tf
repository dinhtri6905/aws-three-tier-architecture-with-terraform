variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Deploy Environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security Group ID for Application Load Balancer"
  type        = string
}

variable "alb_logs_id" {
  description = "ID of the S3 Bucket for ALB access logs"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate used for the HTTPS listener. Leave empty to keep HTTP-only (e.g. dev/lab). When set, an HTTPS listener (443) is created and HTTP (80) redirects to it."
  type        = string
}

variable "ssl_policy" {
  description = "SSL security policy for the HTTPS listener"
  type        = string
}
