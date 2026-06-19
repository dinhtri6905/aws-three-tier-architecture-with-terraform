# Backend Bootstrap

A standalone Terraform module used to **initialize once** the entire infrastructure for storing Terraform remote state: an S3 bucket with KMS encryption and a DynamoDB table for state locking.

---

## Purpose

Before the environments (`dev`, `prod`) can use an S3 remote backend, the S3 bucket and DynamoDB table must exist first. The `backend/` module solves this chicken-and-egg problem by using **local state** to create the backend resources.

```
[Step 1] Run backend/ with local state
    → Creates S3 bucket + DynamoDB table

[Step 2] Environments (dev, prod) use S3 backend
    → Stores state in the newly created S3 bucket
```

---

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_kms_key` | KMS Customer Managed Key for encrypting Terraform state |
| `aws_kms_alias` | Alias `alias/terraform-state` for the KMS key |
| `aws_s3_bucket` | S3 bucket for state storage, `prevent_destroy = true` |
| `aws_s3_bucket_versioning` | Versioning enabled — for state rollback |
| `aws_s3_bucket_server_side_encryption_configuration` | Encrypted with KMS CMK |
| `aws_s3_bucket_public_access_block` | Blocks all public access |
| `aws_dynamodb_table` | DynamoDB table `terraform-state-lock` for state locking |

---

## Security Configuration

| Attribute | Value |
|-----------|-------|
| S3 encryption | `aws:kms` with Customer Managed Key |
| KMS key rotation | `enable_key_rotation = true` (automatic annual rotation) |
| S3 versioning | `Enabled` |
| S3 public access | All 4 settings blocked |
| DynamoDB billing | `PAY_PER_REQUEST` — no capacity provisioning needed |
| S3 lifecycle | `prevent_destroy = true` — prevents accidental deletion |

---

## Variables

| Name | Type | Description |
|------|------|-------------|
| `tfstate_bucket_name` | `string` | S3 bucket name (must be globally unique) |

---

## Outputs

| Name | Description |
|------|-------------|
| `tfstate_bucket_name` | Bucket name — use to configure `backend.tf` in environments |
| `tfstate_bucket_arn` | Bucket ARN |
| `kms_key_arn` | KMS key ARN — use to configure `backend.tf` if you want to specify the key |
| `dynamodb_table_name` | DynamoDB table name (default: `terraform-state-lock`) |

---

## Usage

> Run **once only** during initial project setup.

```bash
cd backend/

# No backend.tf needed — uses local state
terraform init

# Preview
terraform plan -var="tfstate_bucket_name=three-tier-tfstate-2026"

# Create backend infrastructure
terraform apply -var="tfstate_bucket_name=three-tier-tfstate-2026"
```

After apply completes, copy the bucket name into the GitHub Secret `BUCKET_TF_STATE` and update `environments/dev/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "three-tier-tfstate-2026"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

---

## File Structure

```
backend/
├── bootstrap.tf          # KMS, S3, DynamoDB resources
├── variables.tf          # tfstate_bucket_name variable
├── outputs.tf            # Outputs
├── providers.tf          # AWS provider
└── versions.tf           # Terraform and provider versions
```

---

## Notes

- **Local state**: This module uses local state (no `backend.tf`). The state file is stored at `backend/terraform.tfstate` — **commit this file to git or back it up separately**.
- **`prevent_destroy = true`**: The S3 bucket has a prevent_destroy lifecycle — Terraform will error if you try to destroy it. You must remove the lifecycle block first.
- **Run once**: No need to re-run unless you delete the bucket or need a separate bucket for a new environment.
- **KMS key deletion**: The KMS key has `deletion_window_in_days = 7` — after scheduling deletion, you have 7 days to cancel if needed.
