# Module: S3

Creates an S3 bucket for storing Application Load Balancer (ALB) access logs, with full security configuration: public access blocked, versioning enabled, AES-256 encryption, and a lifecycle rule to automatically delete old logs.

---

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_s3_bucket` | S3 bucket for ALB access logs |
| `aws_s3_bucket_public_access_block` | Blocks all public access |
| `aws_s3_bucket_versioning` | Versioning enabled |
| `aws_s3_bucket_server_side_encryption_configuration` | AES-256 encryption |
| `aws_s3_bucket_lifecycle_configuration` | Automatically deletes logs after 30 days |
| `aws_s3_bucket_policy` | Grants ALB service permission to write logs to the bucket |

---

## Security Configuration

| Attribute | Value | Standard |
|-----------|-------|---------|
| `block_public_acls` | `true` | CIS 2.1.3 |
| `block_public_policy` | `true` | CIS 2.1.3 |
| `ignore_public_acls` | `true` | CIS 2.1.3 |
| `restrict_public_buckets` | `true` | CIS 2.1.3 |
| `versioning` | `Enabled` | CIS 2.1.2 |
| `sse_algorithm` | `AES256` | CIS 2.1.1 |

The bucket policy allows the `logdelivery.elasticloadbalancing.amazonaws.com` service to write logs under the `AWSLogs/*` prefix.

---

## Lifecycle Rules

| Rule | Action |
|------|--------|
| `expire_old_logs` | Automatically deletes objects after 30 days |

---

## Variables

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Project name — used to name the bucket |
| `environment` | `string` | Deployment environment (`dev`, `prod`) |

Bucket name is generated with the pattern: `{project_name}-{environment}-alb-logs`

> **Note**: S3 bucket names must be globally unique. If there is a conflict, add a suffix to `project_name` or `environment`.

---

## Outputs

| Name | Description |
|------|-------------|
| `alb_logs_id` | S3 bucket ID — input for the `alb` module (when enabling `access_logs`) |

---

## Usage

```hcl
module "s3" {
  source       = "../../modules/s3"
  project_name = var.project_name
  environment  = var.environment
}
```

Then pass the output to the `alb` module:

```hcl
module "alb" {
  # ...
  alb_logs_id = module.s3.alb_logs_id
}
```

And uncomment the `access_logs` block in `modules/alb/main.tf`:

```hcl
access_logs {
  bucket  = var.alb_logs_id
  prefix  = "alb"
  enabled = true
}
```

---

## Notes

- **OPA compliance**: `compliance.rego` checks that S3 has all 4 public access block settings, versioning enabled, and server-side encryption — this module satisfies all of them.
- **Access log bucket does not self-log**: `CKV_AWS_18` is skipped — the ALB log bucket itself does not need self-logging (would create an infinite loop).
- **KMS encryption**: Currently uses AES-256 (AWS managed). Production can upgrade to `aws:kms` with a Customer Managed Key for finer control over key rotation policies.
- **Cross-region replication**: `CKV_AWS_144` is skipped for lab. Production in a DR (Disaster Recovery) environment should enable this.
