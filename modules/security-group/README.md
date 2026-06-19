# Module: Security Group

Creates Security Groups per tier following the **least-privilege** principle — each tier only accepts the traffic it needs, from the correct source, on the correct port.

---

## Resources Created

| Resource | Name | Description |
|----------|------|-------------|
| `aws_security_group` | `alb-sg`, `app-sg`, `rds-sg` | Empty SGs created first to avoid circular dependency |
| `aws_security_group_rule` | (multiple rules) | Rules created separately to avoid circular dependency |

---

## Traffic Model

```
Internet
    │ HTTP/HTTPS (80/443)
    ▼
┌────────┴────────┐
│    ALB SG       │  ← Open to internet (0.0.0.0/0)
└────────┬────────┘
    │ HTTP from ALB SG only
    ▼
┌────────┴────────┐
│   App SG (EC2)  │  ← Source: ALB SG only
└────────┬────────┘
    │ MySQL 3306 from App SG only
    ▼
┌────────┴────────┐
│    RDS SG       │  ← Source: App SG only
└─────────────────┘
```

---

## Security Group Details

### ALB Security Group

| Direction | Port | Protocol | Source | Purpose |
|-----------|------|----------|--------|---------|
| Ingress | 80 | TCP | `0.0.0.0/0` | Receive HTTP from internet |
| Ingress | 443 | TCP | `0.0.0.0/0` | Receive HTTPS from internet |
| Egress | All | All | `0.0.0.0/0` | Forward to EC2 |

### App (EC2) Security Group

| Direction | Port | Protocol | Source | Purpose |
|-----------|------|----------|--------|---------|
| Ingress | 80 | TCP | ALB SG | Receive HTTP from ALB |
| Ingress | 443 | TCP | ALB SG | Receive HTTPS from ALB |

> SSH (port 22) is commented out. To access EC2, use AWS Systems Manager Session Manager.

### RDS Security Group

| Direction | Port | Protocol | Source | Purpose |
|-----------|------|----------|--------|---------|
| Ingress | 3306 | TCP | EC2 SG | Receive MySQL from App tier |
| Egress | All | All | `0.0.0.0/0` | Outbound (updates, patches) |

---

## Variables

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Project name — used to name the SGs |
| `environment` | `string` | Deployment environment (`dev`, `prod`) |
| `vpc_id` | `string` | ID of the VPC containing the Security Groups |

---

## Outputs

| Name | Description |
|------|-------------|
| `alb_security_group_id` | ALB SG ID — input for the `alb` module |
| `app_security_group_id` | EC2 SG ID — input for the `ec2`, `autoscaling` modules |
| `rds_security_group_id` | RDS SG ID — input for the `rds` module |

---

## Usage

```hcl
module "security-group" {
  source       = "../../modules/security-group"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}
```

---

## Design Notes

- **Separated SG and rules**: Empty SGs are created first; rules are added via `aws_security_group_rule` to avoid circular dependency between the ALB SG and EC2 SG.
- **Source Security Group**: EC2 only accepts traffic from the ALB SG (not CIDR), and RDS only accepts from the EC2 SG — this is best practice over using CIDRs.
- **SSH disabled**: Port 22 is not open to the internet. Use AWS SSM Session Manager to access instances.
- **OPA check**: `networking.rego` will deny if the DB tier Security Group has `protocol=-1` egress to `0.0.0.0/0`.
