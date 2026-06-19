# Environment: Prod

Terraform configuration for the **Production** environment of the AWS three-tier architecture. The prod environment uses stronger sizing, enables Multi-AZ, enables deletion protection, and strictly follows CIS AWS Foundations Benchmark v1.5.0.

---

## Current Status

> **Production environment is not yet configured.** The current files (`main.tf`, `variables.tf`, `outputs.tf`, etc.) are empty. They must be fully populated before deploying to production.

---

## File Structure

```
environments/prod/
├── backend.tf          # Remote state: s3://bucket/prod/terraform.tfstate
├── main.tf             # Module calls (not yet configured)
├── variables.tf        # Variable declarations (not yet configured)
├── outputs.tf          # Outputs (not yet configured)
├── providers.tf        # AWS provider (not yet configured)
└── versions.tf         # Terraform version (not yet configured)
```

---

## Differences from Dev

| Attribute | Dev | Production |
|-----------|-----|------------|
| `instance_type` | `t3.micro` | `t3.medium` or larger |
| `db_instance_class` | `db.t3.micro` | `db.t3.medium` or larger |
| `multi_az` | `false` | **`true`** — required |
| `deletion_protection` | `false` | **`true`** — required |
| `skip_final_snapshot` | `true` | **`false`** — save snapshot before destroy |
| `min_size` ASG | `1` | `2` or more |
| `log_retention_days` | `7` | `30` or longer |
| ALB access_logs | Disabled | **Enabled** |
| HTTPS Listener | Disabled | **Enabled** (ACM certificate) |
| WAF | None | Recommended |
| CloudTrail | None | **Required** (OPA compliance deny) |

---

## Backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "<BUCKET_TF_STATE>"
    key            = "prod/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

The prod state is stored separately from dev at key `prod/terraform.tfstate`.

---

## Production Configuration Guide

### 1. Copy configuration from dev

```bash
cp environments/dev/main.tf environments/prod/main.tf
cp environments/dev/variables.tf environments/prod/variables.tf
cp environments/dev/outputs.tf environments/prod/outputs.tf
cp environments/dev/providers.tf environments/prod/providers.tf
cp environments/dev/versions.tf environments/prod/versions.tf
```

### 2. Create terraform.tfvars for prod

```hcl
# environments/prod/terraform.tfvars

project_name = "three-tier"
environment  = "prod"
aws_region   = "ap-southeast-1"

# Network
vpc_cidr            = "10.1.0.0/16"  # Different CIDR from dev
availability_zones  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
app_subnets_cidrs   = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
db_subnets_cidrs    = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

# EC2 — production sizing
ami_id        = "ami-0543dbdaf4e114be7"
instance_type = "t3.medium"

# Auto Scaling — minimum 2 instances
desired_capacity = 3
min_size         = 2
max_size         = 10

# RDS — production sizing + Multi-AZ
db_instance_class     = "db.t3.medium"
allocated_storage     = 50
max_allocated_storage = 500
database_name         = "appdb"
database_username     = "admin"
database_password     = ""  # From GitHub Secret
multi_az              = true  # REQUIRED for production

# Monitoring
sns_email                   = "oncall@company.com"
asg_cpu_high_threshold      = 70
asg_cpu_low_threshold       = 20
rds_cpu_high_threshold      = 70
rds_free_storage_threshold  = 10737418240  # 10 GB
rds_connections_threshold   = 500
alb_5xx_threshold           = 5
alb_response_time_threshold = 1
log_retention_days          = 30
```

### 3. Update the RDS module for production

In `environments/prod/main.tf`, add to the `rds` module:

```hcl
module "rds" {
  # ...
  multi_az            = true
  deletion_protection = true   # Add this variable
  skip_final_snapshot = false  # Save snapshot on destroy
}
```

---

## Pre-deployment Checklist

- [ ] `multi_az = true` in RDS module
- [ ] `deletion_protection = true` in RDS module
- [ ] `skip_final_snapshot = false` in RDS module
- [ ] HTTPS Listener and ACM certificate configured in ALB module
- [ ] ALB access logs enabled and pointing to S3 bucket
- [ ] CloudTrail created (OPA `compliance.rego` will deny if missing)
- [ ] GitHub Environment `production` has protection rules: required reviewers
- [ ] Slack webhook configured to receive deploy notifications
- [ ] `sns_email` set to the on-call team email address
- [ ] `log_retention_days` set to ≥ 30 days

---

## CI/CD for Production

Production does not auto-deploy. Deploy only via `workflow_dispatch` with action `apply`, requiring confirmation through the GitHub Environment `production`:

```
workflow_dispatch (action=apply)
    │
    ▼
  plan → OPA gate
    │
    ▼ (pass)
  Waiting for approval (GitHub Environment: production)
    │
    ▼ (approved)
  terraform apply
```
