# Module: Auto Scaling

Creates a Launch Template and Auto Scaling Group (ASG) for the Application tier, enabling automatic scaling of EC2 instances based on load, distributed across multiple Availability Zones.

---

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_launch_template` | Instance configuration template (AMI, type, SG, user data, IMDSv2) |
| `aws_autoscaling_group` | ASG managing instance lifecycle, health-checked via ALB |

---

## Launch Template Configuration

| Attribute | Value | Note |
|-----------|-------|------|
| `http_tokens` | `required` | IMDSv2 enforced — OPA `security.rego` denies violations |
| `http_endpoint` | `enabled` | IMDS endpoint enabled |
| `http_put_response_hop_limit` | `1` | Limits hop count for metadata requests |

---

## Auto Scaling Group Configuration

| Attribute | Description |
|-----------|-------------|
| `health_check_type` | `ELB` — ASG uses ALB health check to determine instance health |
| `health_check_grace_period` | 300 seconds — waits for instance boot before starting checks |
| `vpc_zone_identifier` | App private subnet IDs — distributed across AZs |
| `launch_template.version` | `$Latest` — uses the most recent Launch Template version |
| `lifecycle.create_before_destroy` | `true` — zero downtime during instance replacement |

---

## Variables

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Project name |
| `environment` | `string` | Deployment environment (`dev`, `prod`) |
| `ami_id` | `string` | AMI ID |
| `instance_type` | `string` | EC2 instance type (e.g. `t3.micro`) |
| `app_security_group_id` | `string` | SG ID — output from `security-group` module |
| `app_subnet_ids` | `list(string)` | App Subnet IDs — output from `vpc` module |
| `target_group_arn` | `string` | ALB Target Group ARN — output from `alb` module |
| `desired_capacity` | `number` | Desired number of instances |
| `min_size` | `number` | Minimum number of instances |
| `max_size` | `number` | Maximum number of instances |

---

## Outputs

| Name | Description |
|------|-------------|
| `autoscaling_group_name` | ASG name — input for the `monitoring` module |
| `launch_template_id` | Launch Template ID |
| `launch_template_latest_version` | Latest Launch Template version number |

---

## Usage

```hcl
module "autoscaling" {
  source                = "../../modules/autoscaling"
  project_name          = var.project_name
  environment           = var.environment
  ami_id                = var.ami_id
  instance_type         = var.instance_type
  app_security_group_id = module.security-group.app_security_group_id
  app_subnet_ids        = module.vpc.app_subnet_ids
  target_group_arn      = module.alb.target_group_arn
  desired_capacity      = var.desired_capacity
  min_size              = var.min_size
  max_size              = var.max_size
}
```

---

## Notes

- **OPA compliance**: `security.rego` will deny if the Launch Template does not have `http_tokens = "required"` (IMDSv2).
- **OPA warning**: `compliance.rego` will warn if the ASG does not span at least 2 AZs — ensure `app_subnet_ids` includes subnets from ≥ 2 AZs.
- **Scale policy**: This module does not create scaling policies. To auto-scale by CPU, add `aws_autoscaling_policy` and link it to a CloudWatch alarm from the `monitoring` module.
- **ELB health check**: ASG uses ALB health check instead of EC2 health check — instances will be terminated if ALB reports them as unhealthy.
