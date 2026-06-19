# Module: Application Load Balancer (ALB)

Creates an internet-facing Application Load Balancer, Target Group, and HTTP Listener for the Web tier of the three-tier architecture.

---

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_lb` | Internet-facing ALB, deployed across multiple AZs |
| `aws_lb_target_group` | Target Group receiving traffic from ALB, health check every 30 seconds |
| `aws_lb_listener` | HTTP Listener on port 80, forwarding to Target Group |

---

## Architecture

```
Internet
    │  HTTP (port 80)
    ▼
┌──────────────────────────────────────────────┐
│               aws_lb                          │
│  internet-facing · multi-AZ · drop headers   │
└──────────────────┬───────────────────────────┘
                   │
    ┌──────────────┴──────────────┐
    │       aws_lb_listener       │
    │         (port 80)           │
    └──────────┬──────────────────┘
               │ forward
        ┌──────┴──────┐
        │ Target Group │
        └──────┬───────┘
               │
        ┌──────┴──────────┐
        │  EC2 / ASG       │  (App tier private subnets)
        └─────────────────┘
```

---

## Configuration Details

### ALB

| Attribute | Value | Note |
|-----------|-------|------|
| `internal` | `false` | Internet-facing |
| `load_balancer_type` | `application` | Application Load Balancer |
| `drop_invalid_header_fields` | `true` | Security — CKV_AWS_131 |
| `enable_deletion_protection` | `false` | Disabled for lab; enable for production |
| `subnets` | Public subnets | At least 2 AZs required (OPA check) |

### Target Group

| Attribute | Value |
|-----------|-------|
| `port` | `80` |
| `protocol` | `HTTP` |
| `target_type` | `instance` |
| `health_check.path` | `/` |
| `health_check.interval` | 30 seconds |
| `healthy_threshold` | 2 consecutive successes |
| `unhealthy_threshold` | 2 consecutive failures |

### HTTP Listener

| Attribute | Value |
|-----------|-------|
| `port` | `80` |
| `protocol` | `HTTP` |
| `default_action` | `forward` to Target Group |

---

## Variables

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Project name |
| `environment` | `string` | Deployment environment (`dev`, `prod`) |
| `vpc_id` | `string` | VPC ID |
| `public_subnet_ids` | `list(string)` | Public Subnet IDs (≥ 2 subnets, ≥ 2 AZs) |
| `alb_security_group_id` | `string` | SG ID for ALB — output from `security-group` module |
| `alb_logs_id` | `string` | S3 bucket ID for access logs — output from `s3` module |

---

## Outputs

| Name | Description |
|------|-------------|
| `alb_id` | ALB ID |
| `alb_arn` | ALB ARN |
| `alb_arn_suffix` | ARN suffix — used as a CloudWatch dimension |
| `alb_dns_name` | DNS name for accessing the application |
| `alb_zone_id` | ALB Zone ID (for Route 53 alias records) |
| `target_group_name` | Target Group name |
| `target_group_arn_suffix` | Target Group ARN suffix — used for CloudWatch |

---

## Usage

```hcl
module "alb" {
  source                = "../../modules/alb"
  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security-group.alb_security_group_id
  alb_logs_id           = module.s3.alb_logs_id
}
```

After deployment, access the application at:

```
# → three-tier-dev-alb-xxxxxxxxx.ap-southeast-1.elb.amazonaws.com
terraform output alb_dns_name
```

---

## Notes

- **Multi-AZ**: OPA policy (`networking.rego`) will deny if the ALB is deployed across fewer than 2 subnets — always pass at least 2 public subnets from 2 different AZs.
- **HTTPS**: The listener currently uses HTTP (port 80). Production should add an HTTPS Listener with an ACM certificate and an HTTP → HTTPS redirect.
- **Access logs**: The `access_logs` block is prepared but commented out. Uncomment and pass `alb_logs_id` to enable in production.
- **WAF**: `CKV2_AWS_28` is skipped. Production should attach an AWS WAF WebACL to the ALB.
