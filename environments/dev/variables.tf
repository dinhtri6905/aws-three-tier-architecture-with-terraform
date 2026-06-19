# ============================================================
# GENERAL 
# ============================================================
variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "three-tier"
}

variable "environment" {
  description = "Deploy Environment"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

# ============================================================
# VPC 
# ============================================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "app_subnets_cidrs" {
  description = "Application subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24"
  ]
}

variable "db_subnets_cidrs" {
  description = "Database subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.0.21.0/24",
    "10.0.22.0/24",
    "10.0.23.0/24"
  ]
}

variable "availability_zones" {
  description = "Availability Zones"
  type        = list(string)

  default = [
    "ap-southeast-1a",
    "ap-southeast-1b",
    "ap-southeast-1c"
  ]
}

# ============================================================
# SECURITY GROUP 
# ============================================================


# ============================================================
# APPLICATION LOAD BALANCER 
# ============================================================
variable "certificate_arn" {
  description = "ARN of the ACM certificate used for the HTTPS listener. Leave empty to keep HTTP-only (e.g. dev/lab). When set, an HTTPS listener (443) is created and HTTP (80) redirects to it."
  type        = string
  default     = ""
  # HTTP requests on port 80 are permanently redirected to HTTPS (443).
  # A valid ACM certificate is required for the HTTPS listener.

  # To create an ACM certificate:
  # AWS Console → Certificate Manager → Request Certificate
}

variable "ssl_policy" {
  description = "SSL security policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

# ============================================================
# EC2 
# ============================================================
variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0543dbdaf4e114be7"
}
# ami = ami-0543dbdaf4e114be7 / ami-0d105bf3c7d10a264

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# ============================================================
# AUTOSCALING 
# ============================================================
variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 4
}

# ============================================================
# RDS 
# ============================================================
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaling storage (GB)"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "dbthreetier"
}

variable "database_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable RDS deletion protection. Should be true for production."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip taking a final snapshot when the RDS instance is destroyed. Should be false for production."
  type        = bool
  default     = true
}

# ============================================================
# MONITORING 
# ============================================================
variable "sns_email" {
  description = "Email address to receive CloudWatch alerts. Leave empty to disable."
  type        = string
  default     = ""
}

variable "asg_cpu_high_threshold" {
  description = "ASG CPU high threshold (%), alarm triggers when CPU exceeds this value"
  type        = number
  default     = 80
}

variable "asg_cpu_low_threshold" {
  description = "ASG CPU low threshold (%), alarm triggers when CPU drops below this value"
  type        = number
  default     = 20
}

variable "rds_cpu_high_threshold" {
  description = "RDS CPU high threshold (%)"
  type        = number
  default     = 80
}

variable "rds_free_storage_threshold" {
  description = "RDS free storage threshold (bytes). Default is 5 GB"
  type        = number
  default     = 5368709120
}

variable "rds_connections_threshold" {
  description = "Maximum number of concurrent RDS connections threshold"
  type        = number
  default     = 100
}

variable "alb_5xx_threshold" {
  description = "Number of ALB 5xx errors per minute threshold"
  type        = number
  default     = 10
}

variable "alb_response_time_threshold" {
  description = "Average ALB response time (seconds), alarm triggers when this threshold is exceeded"
  type        = number
  default     = 2
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch Log Groups"
  type        = number
  default     = 14

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653],
      var.log_retention_days
    )
    error_message = "log_retention_days must be a valid CloudWatch Logs retention period: 1, 3, 5, 7, 14, 30, 60, 90, ..."
  }
}

