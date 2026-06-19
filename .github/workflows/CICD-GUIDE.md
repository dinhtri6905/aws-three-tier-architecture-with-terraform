## Architecture Diagram

![CICD_Pipeline](../../images/cicd_pipeline.png)

---

# CI/CD Pipeline Setup Guide

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Step 1 — Create IAM User on AWS](#step-1--create-iam-user-on-aws)
3. [Step 2 — Create S3 Bucket for Terraform State](#step-2--create-s3-bucket-for-terraform-state)
4. [Step 3 — Configure GitHub Secrets](#step-3--configure-github-secrets)
5. [Step 4 — Configure GitHub Environments](#step-4--configure-github-environments)
6. [Step 5 — Verify Required File Structure](#step-5--verify-required-file-structure)
7. [How to run terraform-ci.yml](#how-to-run-terraform-ciyml)
8. [How to run terraform-cd.yml](#how-to-run-terraform-cdyml)
9. [How to run check-scan.yml](#how-to-run-check-scanyml)
10. [Troubleshooting Common Errors](#troubleshooting-common-errors)

---

## 1. Prerequisites

Before running any workflow, ensure the following are ready:

| Item | Required | Used by |
|------|----------|---------|
| AWS Account + IAM User | Required | terraform-cd, check-scan |
| S3 Bucket for Terraform state | Required | terraform-cd, check-scan |
| GitHub Secrets (5 variables) | Required | All 3 workflows |
| GitHub Environments | Required | terraform-cd |
| `terraform.tfvars` file in `environments/dev/` | Required | terraform-cd, check-scan |
| Slack Webhook URL | Optional | All 3 workflows |

---

## Step 1 — Create IAM User on AWS

CI/CD requires an IAM User with sufficient permissions to provision the entire three-tier infrastructure.

### 1.1 Create IAM User

```
AWS Console -> IAM -> Users -> Create user
User name: github-actions-dev
Access type: Programmatic access (Access key)
```

### 1.2 Attach IAM Policy

Create a custom policy named `GitHubActionsDeployPolicy` and paste the following content:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2Permissions",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RDSPermissions",
      "Effect": "Allow",
      "Action": [
        "rds:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ElasticLoadBalancingPermissions",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AutoScalingPermissions",
      "Effect": "Allow",
      "Action": [
        "autoscaling:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:GetRole",
        "iam:PassRole",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:ListInstanceProfilesForRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3StatePermissions",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:GetBucketAcl",
        "s3:GetBucketLogging",
        "s3:GetBucketPolicy",
        "s3:GetEncryptionConfiguration"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME",
        "arn:aws:s3:::YOUR-BUCKET-NAME/*"
      ]
    },
    {
      "Sid": "CloudWatchPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:*",
        "logs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudTrailPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudtrail:*"
      ],
      "Resource": "*"
    }
  ]
}
```

> Replace `YOUR-BUCKET-NAME` with the S3 bucket name you will create in Step 2.

### 1.3 Retrieve Access Key

```
IAM -> Users -> github-actions-dev -> Security credentials
-> Create access key -> Application running outside AWS
```

Save:
- `Access key ID` → will be used for secret `AWS_ACCESS_KEY_ID`
- `Secret access key` → will be used for secret `AWS_SECRET_ACCESS_KEY`

---

## Step 2 — Create S3 Bucket for Terraform State

Terraform requires an S3 bucket to store the state file. The bucket must be created **before** running CI/CD.

### 2.1 Create bucket using AWS CLI

```bash
# Replace YOUR-BUCKET-NAME with your bucket name (must be globally unique)
# Example: three-tier-terraform-state-2026

aws s3api create-bucket \
  --bucket YOUR-BUCKET-NAME \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

# Enable versioning (important — allows state rollback if needed)
aws s3api put-bucket-versioning \
  --bucket YOUR-BUCKET-NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket YOUR-BUCKET-NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket YOUR-BUCKET-NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### 2.2 Create DynamoDB Table for State Locking (recommended)

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```

### 2.3 Configure backend.tf in environments/dev/

```hcl
# environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "YOUR-BUCKET-NAME"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 2.4 Alternative: use the backend/ Terraform module

```bash
cd backend/
terraform init
terraform plan
terraform apply
```

---

## Step 3 — Configure GitHub Secrets

In your GitHub repository:

```
Settings -> Secrets and variables -> Actions -> New repository secret
```

Create the following 5 secrets:

| Secret Name | Value | Required |
|-------------|-------|----------|
| `AWS_ACCESS_KEY_ID` | Access key ID from Step 1.3 | Required |
| `AWS_SECRET_ACCESS_KEY` | Secret access key from Step 1.3 | Required |
| `BUCKET_TF_STATE` | S3 bucket name from Step 2 | Required |
| `DB_PASSWORD` | RDS password (minimum 8 characters) | Required |
| `SLACK_WEBHOOK_URL` | Webhook URL from Slack App | Optional |

### Create Slack Webhook (optional, for notifications)

```
Slack -> Apps -> Incoming Webhooks -> Add to Slack
-> Select channel -> Copy Webhook URL
```

---

## Step 4 — Configure GitHub Environments

Environments are used to control deployments (can include manual approval gates).

```
GitHub Repo -> Settings -> Environments -> New environment
```

Create 2 environments:

**Environment `development`**
```
Name: development
Protection rules: (no reviewer required for dev)
```

**Environment `production`** (for future prod expansion)
```
Name: production
Protection rules:
  - Required reviewers: [add reviewer names]
  - Wait timer: 0 minutes
```

> Currently only deploys dev. The production environment can be created now to be ready when needed.

---

## Step 5 — Verify Required File Structure

Before pushing code, confirm the following files exist in the repository:

```
AWS-Three-Tier-Architecture/
│
├── .github/
│   └── workflows/
│       ├── terraform-ci.yml       <- Workflow file
│       ├── terraform-cd.yml       <- Workflow file
│       └── check-scan.yml         <- Workflow file
│
├── environments/
│   └── dev/
│       ├── backend.tf             <- S3 backend config (Step 2.3)
│       ├── main.tf                <- Module calls
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── versions.tf
│       └── terraform.tfvars       <- Actual variable values (IMPORTANT)
│
├── modules/
│   ├── vpc/
│   ├── security-group/
│   ├── alb/
│   ├── ec2/
│   ├── autoscaling/
│   ├── rds/
│   └── monitoring/
│
└── policies/
    ├── security.rego
    ├── networking.rego
    └── compliance.rego
```

### Sample terraform.tfvars file

```hcl
# environments/dev/terraform.tfvars

# General
environment = "dev"
project     = "three-tier-arch"
aws_region  = "ap-southeast-1"

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
db_subnet_cidrs      = ["10.0.21.0/24", "10.0.22.0/24"]

# EC2 Web Tier
web_instance_type = "t3.micro"
web_ami_id        = "ami-0c02fb55956c7d316"   # Amazon Linux 2, ap-southeast-1

# EC2 App Tier
app_instance_type = "t3.micro"
app_ami_id        = "ami-0c02fb55956c7d316"

# RDS
db_instance_class   = "db.t3.micro"
db_engine           = "mysql"
db_engine_version   = "8.0"
db_name             = "appdb"
db_username         = "admin"
# db_password is passed via TF_VAR_db_password from GitHub Secret

# Tags
tags = {
  Environment = "dev"
  Project     = "three-tier-arch"
  ManagedBy   = "Terraform"
}
```

---

## How to run terraform-ci.yml

This file runs **automatically** — no manual action required.

### When it runs automatically

```
Push code to develop branch   ->  CI runs immediately
Push code to feature/* branch ->  CI runs immediately (SOFT_FAIL=true, scan errors don't block)
Create Pull Request to develop ->  CI runs and comments results on PR
```

### Detailed flow

```
[Push/PR]
    |
    v
validate (fmt check + init -backend=false + validate)
    |
    +------------------+------------------+
    v                  v                  v
 tflint             tfsec             checkov
(AWS ruleset)   (IaC security)   (CIS/NIST scan)
    |                  |                  |
    +------------------+------------------+
                       |
                       v
                  ci-summary
         (PR comment + Slack notify)
```

### Viewing results

- **GitHub Actions tab**: view detailed logs per step
- **Pull Request**: 5 automatic comments (validate, tflint, checkov, tfsec, summary)
- **Security tab** (GitHub): Checkov results as SARIF
- **Artifacts**: download `tflint-report.json`, `checkov-report` for offline review

---

## How to run terraform-cd.yml

### Case 1 — Auto deploy (push to develop)

```bash
git checkout develop
git add .
git commit -m "feat: add vpc module"
git push origin develop
```

After pushing, GitHub Actions automatically runs:

```
push to develop
    |
    v
plan (terraform plan + export JSON)
    |
    v
opa-gate (checks 3 policy files)
    |           |
  FAIL         PASS
    |           |
  Stop         v
           deploy (terraform apply)
               |
               v
           notify Slack
```

### Case 2 — Manual run (workflow_dispatch)

```
GitHub Repo -> Actions -> Terraform CD -> Run workflow
```

Select `action`:

| action | Result |
|--------|--------|
| `plan` | Runs terraform plan only, previews changes, does not apply |
| `apply` | plan -> OPA gate -> apply |
| `destroy` | Destroys all dev infrastructure |

**Important with `destroy`**: the workflow requires confirmation through GitHub Environment approval before actually destroying.

### Viewing plan results

```
Actions -> Terraform CD -> [specific run] -> plan job -> Step Summary
```

The full plan is printed in Step Summary, including the count of resources to create/update/destroy.

### Viewing OPA results

```
Actions -> Terraform CD -> [specific run] -> opa-gate job
```

Each OPA step prints:
```
# If pass:
Security: PASS (0 violations)

# If fail:
--- Security violations: 2 ---
  [DENY] RDS instance 'module.rds.aws_db_instance.main': storage_encrypted must be true
  [DENY] Security Group Rule '...': SSH (port 22) must not be open to the internet
```

---

## How to run check-scan.yml

### Case 1 — Automatic (daily at 2:00 AM GMT+7)

No action needed. The workflow runs automatically on cron `0 19 * * *` (19:00 UTC = 02:00 GMT+7).

### Case 2 — Manual run

```
GitHub Repo -> Actions -> Security and Compliance Scan -> Run workflow
```

Select `scan_type`:

| scan_type | Runs |
|-----------|------|
| `all` | OPA full scan + tfsec deep |
| `opa-only` | OPA only with the latest plan JSON |
| `tfsec-only` | tfsec deep scan only |

### Viewing reports

```
Actions -> [specific run] -> Summary tab
```

Step Summary displays an aggregated table:

```
## Security and Compliance Scan Summary - DEV

Scan date: 2024-01-15 19:00 UTC

### OPA Policy Results
| Policy     | Deny | Warn |
|------------|------|------|
| Security   |  0   |  2   |
| Networking |  0   |  1   |
| Compliance |  0   |  3   |

### tfsec Results
Issues found: 5
```

Download artifact for details:
```
Actions -> [specific run] -> Artifacts
  - opa-full-report    (opa-results.json)
  - tfsec-deep-report  (tfsec-report.json)
```

---

## Troubleshooting Common Errors

### Error 1: `Error: No valid credential sources found`

```
Cause : GitHub Secret AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY is wrong or missing
Fix   : Settings -> Secrets -> Verify both secrets
        Ensure IAM User is still active and Access Key is not disabled
```

### Error 2: `Error: Failed to get existing workspaces: S3 bucket does not exist`

```
Cause : Bucket in BUCKET_TF_STATE does not exist or name is incorrect
Fix   : Re-run Step 2 to create the bucket
        Verify bucket name in the secret matches backend.tf
```

### Error 3: `terraform fmt -check failed`

```
Cause : Terraform code is not properly formatted
Fix   : Run locally before pushing:
        cd environments/dev && terraform fmt -recursive
```

### Error 4: OPA gate fails with violations

```
Cause : Infrastructure code violates a policy in policies/*.rego
Fix   : Read the [DENY] message in the log to identify which resource is in violation
        Fix the Terraform code to comply with the policy
        Example: add storage_encrypted = true to aws_db_instance
```

### Error 5: `TFLint: Failed to initialize plugins`

```
Cause : Network timeout when downloading AWS ruleset
Fix   : Re-run the job (usually a transient error)
        Or commit .tflint.hcl to the repo instead of generating it inline
```

### Error 6: Checkov fails but you want to skip certain checks

```
Cause : Some CIS checks do not apply to the dev environment
Fix   : Add skip_check to the checkov-action in terraform-ci.yml
        Example:
          skip_check: CKV_AWS_144,CKV_AWS_117

        Or add an inline comment in Terraform:
          #checkov:skip=CKV_AWS_144: Dev environment, no cross-region replication needed
```

### Error 7: `Plan JSON exported but OPA returns no results`

```
Cause : Package name in the rego file does not match the query path
Fix   : Check the first line of each file:
        security.rego   -> package terraform.security
        networking.rego -> package terraform.networking
        compliance.rego -> package terraform.compliance

        Query in the workflow must be:
        data.terraform.security.deny
        data.terraform.networking.deny
        data.terraform.compliance.deny
```

---

## Pre-run Checklist

```
[ ] IAM User created with Access Key + Secret Key
[ ] IAM Policy attached with sufficient permissions
[ ] S3 bucket created with versioning + encryption enabled
[ ] DynamoDB table created (for state locking)
[ ] backend.tf in environments/dev/ points to correct bucket
[ ] terraform.tfvars in environments/dev/ has all required variables
[ ] 5 GitHub Secrets configured (4 required + 1 Slack)
[ ] 2 GitHub Environments created (development, production)
[ ] CI/CD workflow files committed to the correct paths
[ ] Local test passed: cd environments/dev && terraform init && terraform validate
```
