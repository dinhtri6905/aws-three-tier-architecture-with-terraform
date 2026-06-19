variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Deploy Environment"
  type        = string
}

variable "db_subnet_ids" {
  description = "Database subnet IDs"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "RDS Security Group ID"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage (GB)"
  type        = number
}

variable "max_allocated_storage" {
  description = "Maximum autoscaling storage (GB)"
  type        = number
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "database_username" {
  description = "Database master username"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
}

variable "deletion_protection" {
  description = "Enable RDS deletion protection. Should be true for production."
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Skip taking a final snapshot when the RDS instance is destroyed. Should be false for production."
  type        = bool
}
