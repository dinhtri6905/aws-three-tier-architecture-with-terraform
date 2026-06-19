# Policies — Policy-as-Code with OPA/Rego

The `policies/` directory contains 3 Rego files that are automatically executed in the CI/CD pipeline before any Terraform resource is created. Each time `terraform plan` produces a JSON plan, OPA evaluates it against the rules below.

---

## Overview

```
tfplan.json  (terraform plan -out=plan.tfplan && terraform show -json plan.tfplan)
    │
    ├── security.rego    → data.terraform.security.deny / .warn
    ├── networking.rego  → data.terraform.networking.deny / .warn
    └── compliance.rego  → data.terraform.compliance.deny / .warn
```

**Result classification:**
- `deny` — critical violation. Pipeline stops, no apply.
- `warn` — warning. Printed to log but pipeline continues.

---

## security.rego

Checks security for each service: EC2, Launch Template, RDS, Security Group, IAM.

### Deny rules

| Rule | Resource | Condition |
|------|----------|-----------|
| IMDSv2 required | `aws_instance`, `aws_launch_template` | `http_tokens != "required"` |
| RDS encryption | `aws_db_instance` | `storage_encrypted != true` |
| RDS private | `aws_db_instance` | `publicly_accessible != false` |
| RDS backup | `aws_db_instance` | `backup_retention_period < 7` |
| SSH public | `aws_security_group_rule` | port 22 from `0.0.0.0/0` |
| RDP public | `aws_security_group_rule` | port 3389 from `0.0.0.0/0` |
| DB port public | `aws_security_group_rule` | port 3306/5432 from `0.0.0.0/0` |
| All traffic public | `aws_security_group_rule` | `protocol = -1` from `0.0.0.0/0` |
| IAM wildcard | `aws_iam_policy` | `Action = *` and `Resource = *` |
| IAM user policy | `aws_iam_user_policy` | Any user inline policy |

### Warn rules

| Rule | Condition |
|------|-----------|
| ALB access logs | `access_logs.enabled != true` |
| RDS deletion protection | `deletion_protection != true` |
| EC2 no key_name | No key pair → ensure SSM Session Manager is available |

---

## networking.rego

Checks proper network isolation per tier.

### Deny rules

| Rule | Resource | Condition |
|------|----------|-----------|
| VPC DNS | `aws_vpc` | `enable_dns_hostnames` or `enable_dns_support` = false |
| Private subnet no public IP | `aws_subnet` (Tier=app/database) | `map_public_ip_on_launch = true` |
| App EC2 no public IP | `aws_instance` (Tier=app) | `associate_public_ip_address = true` |
| RDS subnet group | `aws_db_instance` | `db_subnet_group_name` is empty |
| ALB internet-facing | `aws_lb` (Tier=web) | `internal = true` |
| ALB multi-AZ | `aws_lb` | Fewer than 2 subnets |
| SG description | `aws_security_group` | `description = "managed by terraform"` |
| DB egress | `aws_security_group_rule` (DB SG) | `protocol = -1` egress to `0.0.0.0/0` |

### Warn rules

| Rule | Condition |
|------|-----------|
| VPC Flow Logs | No `aws_flow_log` in plan |
| HTTPS Listener | Web tier ALB Listener uses port 80 instead of 443 |
| NAT Gateway | No `aws_nat_gateway` in plan |

---

## compliance.rego

Checks compliance with **CIS AWS Foundations Benchmark v1.5.0** and the organizational Tagging Policy.

### Deny rules — CIS

| Rule | CIS ID | Resource | Condition |
|------|--------|----------|-----------|
| S3 encryption | 2.1.1 | `aws_s3_bucket` | No `server_side_encryption_configuration` |
| S3 versioning | 2.1.2 | `aws_s3_bucket_versioning` | `status != "Enabled"` |
| S3 public access block | 2.1.3 | `aws_s3_bucket_public_access_block` | Any of the 4 block settings missing |
| CloudTrail required | 3.1 | — | No `aws_cloudtrail` in plan |
| CloudTrail log validation | 3.2 | `aws_cloudtrail` | `enable_log_file_validation != true` |
| CloudTrail CloudWatch | 3.4 | `aws_cloudtrail` | No `cloud_watch_logs_group_arn` |
| CloudTrail multi-region | 3.5 | `aws_cloudtrail` | `is_multi_region_trail != true` |
| IAM no user policy | 5.1 | `aws_iam_user_policy` | Any user inline policy exists |
| IAM no wildcard | 5.2 | `aws_iam_policy` | `Action = *` and `Resource = *` |
| RDS encryption | 5.4 | `aws_db_instance` | `storage_encrypted != true` |

### Deny rules — Tagging Policy

The following resources must have all 3 tags: `Environment`, `Project`, `ManagedBy`:

`aws_instance`, `aws_db_instance`, `aws_lb`, `aws_vpc`, `aws_subnet`, `aws_security_group`, `aws_s3_bucket`

### Warn rules

| Rule | CIS | Condition |
|------|-----|-----------|
| S3 access logging | 2.1.4 | No access logging configured |
| CloudWatch unauthorized API alarm | 4.1 | No alarm for unauthorized calls |
| RDS Multi-AZ | — | `multi_az != true` |
| ASG multi-AZ | — | ASG spans fewer than 2 AZs |

---

## Running OPA manually

```bash
# Install OPA
brew install opa  # macOS
# or: https://www.openpolicyagent.org/docs/latest/#running-opa

# Generate plan JSON
cd environments/dev
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Run individual policies
opa eval -d ../../policies/security.rego   -i tfplan.json "data.terraform.security.deny"
opa eval -d ../../policies/networking.rego -i tfplan.json "data.terraform.networking.deny"
opa eval -d ../../policies/compliance.rego -i tfplan.json "data.terraform.compliance.deny"

# View both deny and warn
opa eval -d ../../policies/ -i tfplan.json "data.terraform"
```

---

## Reading OPA results

```json
{
  "result": [{
    "expressions": [{
      "value": [
        "RDS instance three-tier-dev-mysql must have storage_encrypted = true",
        "EC2 instance must enforce IMDSv2 (http_tokens = required)"
      ]
    }]
  }]
}
```

Each element in the array is a violation. An empty array `[]` means no violations.

---

## Adding new rules

```rego
# Example: deny if EC2 does not have an "Owner" tag
deny[msg] {
  r := input.resource_changes[_]
  r.type == "aws_instance"
  r.change.actions[_] == "create"
  not r.change.after.tags.Owner
  msg := sprintf("EC2 instance '%s' must have 'Owner' tag", [r.address])
}
```

Add the rule to the corresponding `.rego` file and push — the pipeline will automatically apply it on the next deploy.
