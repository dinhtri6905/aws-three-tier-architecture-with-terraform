# Environment: Dev

Terraform configuration for the **Development** environment of the AWS three-tier architecture. The dev environment is optimized for low cost and fast deployment speed while maintaining the full security structure of production.

---

## File Structure

```
environments/dev/
├── backend.tf          # Remote state: S3 + DynamoDB lock
├── main.tf             # Module calls in dependency order
├── variables.tf        # All variable declarations with dev defaults
├── outputs.tf          # Key outputs after deployment
├── providers.tf        # AWS provider, region ap-southeast-1
├── versions.tf         # Minimum Terraform and provider versions
└── terraform.tfvars    # Actual variable values (do not commit to git)
```

---

## Modules Called

```
main.tf
├── module "vpc"            → modules/vpc
├── module "security-group" → modules/security-group
├── module "s3"             → modules/s3
├── module "alb"            → modules/alb
├── module "ec2"            → modules/ec2
├── module "autoscaling"    → modules/autoscaling
├── module "rds"            → modules/rds
└── module "monitoring"     → modules/monitoring
```

Dependency order: `vpc` → `security-group` + `s3` → `alb` → `ec2` + `autoscaling` → `rds` → `monitoring`

---

## Remote State Backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "<BUCKET_TF_STATE>"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

The dev environment state file is stored at: `s3://<bucket>/dev/terraform.tfstate`

---

## Dev Default Values

| Variable | Default | Note |
|----------|---------|------|
| `environment` | `dev` | |
| `aws_region` | `ap-southeast-1` | Singapore |
| `vpc_cidr` | `10.0.0.0/16` | |
| `availability_zones` | `[a, b, c]` | 3 AZs |
| `instance_type` | `t3.micro` | Free tier eligible |
| `db_instance_class` | `db.t3.micro` | Smallest, reduces cost |
| `multi_az` | `false` | Disabled to reduce dev cost |
| `desired_capacity` | `2` | |
| `min_size` | `1` | |
| `max_size` | `4` | |
| `allocated_storage` | `20` GB | |
| `max_allocated_storage` | `100` GB | |
| `log_retention_days` | `7` | |

---

## terraform.tfvars Configuration

Create the file `environments/dev/terraform.tfvars` with the following content:

```hcl
# Project
project_name = "three-tier"
environment  = "dev"
aws_region   = "ap-southeast-1"

# Network
vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
app_subnets_cidrs   = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
db_subnets_cidrs    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

# EC2
ami_id        = "ami-0543dbdaf4e114be7"  # Amazon Linux 2, ap-southeast-1
instance_type = "t3.micro"

# Auto Scaling
desired_capacity = 2
min_size         = 1
max_size         = 4

# RDS
db_instance_class     = "db.t3.micro"
allocated_storage     = 20
max_allocated_storage = 100
database_name         = "appdb"
database_username     = "admin"
database_password     = ""  # Passed via GitHub Secret DB_PASSWORD
multi_az              = false

# Monitoring
sns_email                   = ""  # Email address for alerts
asg_cpu_high_threshold      = 80
asg_cpu_low_threshold       = 20
rds_cpu_high_threshold      = 80
rds_free_storage_threshold  = 5368709120  # 5 GB
rds_connections_threshold   = 100
alb_5xx_threshold           = 10
alb_response_time_threshold = 2
log_retention_days          = 7
```

> **Do not commit `terraform.tfvars`** — this file is added to `.gitignore`.

---

## Manual Deploy

```bash
cd environments/dev

# 1. Initialize backend
terraform init

# 2. Validate syntax
terraform validate
terraform fmt -check
# terraform fmt -recursive

# 3. Preview changes
terraform plan -var="database_password=<password>"

# 4. Apply
terraform apply -var="database_password=<password>"
```

---

## Deploy via CI/CD

Merging into the `develop` branch automatically triggers `terraform-cd.yml`:

```
develop branch push
    │
    ▼
  plan → OPA gate (security + networking + compliance)
    │
    ▼ (pass)
  terraform apply
```

---

## Key Outputs

After deployment, the following outputs are displayed:

```bash
terraform output alb_dns_name       # Application access URL
terraform output rds_endpoint       # RDS connection endpoint
terraform output dashboard_url      # CloudWatch Dashboard URL
```

---

## Destroy

```bash
# Manual
terraform destroy -var="database_password=<password>"

# Via CI/CD (workflow_dispatch with action=destroy)
# → Requires confirmation via GitHub Environment protection rules
```

> **Warning**: Destroy will delete all infrastructure including RDS (`skip_final_snapshot = true`). Ensure data is backed up before destroying.
