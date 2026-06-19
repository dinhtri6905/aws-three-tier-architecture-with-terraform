# Module: RDS

Creates an Amazon RDS MySQL 8.0 instance for the Data tier, fully isolated in private subnets, with encryption enabled, automated backups, and no public access.

---

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_db_subnet_group` | DB Subnet Group — groups the private DB subnets |
| `aws_db_instance` | RDS MySQL 8.0 instance |

---

## Security Configuration (enforced by OPA policy)

| Attribute | Value | OPA Rule |
|-----------|-------|----------|
| `publicly_accessible` | `false` | `security.rego` → deny if true |
| `storage_encrypted` | `true` | `security.rego` → deny if false |
| `backup_retention_period` | `7` days | `security.rego` → deny if < 7 |
| `db_subnet_group_name` | required | `networking.rego` → deny if missing |
| `storage_type` | `gp3` | Better performance than gp2 |
| `auto_minor_version_upgrade` | `true` | Automatic security patching |
| `copy_tags_to_snapshot` | `true` | Tags copied to snapshots |

---

## Storage Configuration

| Attribute | Default | Description |
|-----------|---------|-------------|
| `storage_type` | `gp3` | General Purpose SSD generation 3 |
| `allocated_storage` | `20` GB | Initial storage capacity |
| `max_allocated_storage` | `100` GB | Maximum capacity limit for storage autoscaling |

Storage Autoscaling automatically expands when remaining capacity falls below 10% or below 5 GB.

---

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | `string` | — | Project name |
| `environment` | `string` | — | Deployment environment |
| `db_subnet_ids` | `list(string)` | — | DB Subnet IDs — output from `vpc` module |
| `rds_security_group_id` | `string` | — | SG ID — output from `security-group` module |
| `db_instance_class` | `string` | `db.t3.micro` | RDS instance class |
| `allocated_storage` | `number` | `20` | Initial storage (GB) |
| `max_allocated_storage` | `number` | `100` | Maximum autoscale storage (GB) |
| `database_name` | `string` | — | Name of the database to create |
| `database_username` | `string` | — | Database master username |
| `database_password` | `string` | — | Database master password (sensitive) |
| `multi_az` | `bool` | `false` | Enable Multi-AZ for high availability |

---

## Outputs

| Name | Description |
|------|-------------|
| `rds_instance_id` | RDS instance identifier — input for the `monitoring` module |
| `rds_instance_arn` | RDS instance ARN |
| `rds_endpoint` | Full endpoint (`host:port`) for connections |
| `rds_address` | RDS hostname (without port) |
| `database_name` | Database name |

---

## Usage

```hcl
module "rds" {
  source                = "../../modules/rds"
  project_name          = var.project_name
  environment           = var.environment
  db_subnet_ids         = module.vpc.db_subnet_ids
  rds_security_group_id = module.security-group.rds_security_group_id
  db_instance_class     = var.db_instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  database_name         = var.database_name
  database_username     = var.database_username
  database_password     = var.database_password  # From GitHub Secret
  multi_az              = var.multi_az
}
```

---

## Notes

- **Password**: Do not hardcode passwords in code. Pass via the `database_password` variable configured through GitHub Secret `DB_PASSWORD`.
- **Multi-AZ**: `multi_az = false` for dev/lab to reduce cost. Production requires `multi_az = true` — OPA will warn if false.
- **Deletion protection**: Disabled for lab (`skip_final_snapshot = true`, `deletion_protection = false`). Production should enable both.
- **Port protection**: The RDS SG only opens port 3306 from the EC2 SG — no direct connection from a personal machine or the internet is possible.
- **Encryption**: `storage_encrypted = true` uses the default AWS managed key. Production can use a KMS Customer Managed Key for more control.
