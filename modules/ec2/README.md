# Module: EC2

Creates EC2 instances for the Application tier, placed in private subnets, with IMDSv2 security, EBS encryption, and automatic registration into the ALB Target Group.

---

## Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_instance` | N (one per App Subnet) | EC2 application server, 1 instance per AZ |
| `aws_lb_target_group_attachment` | N | Registers each instance into the ALB Target Group |

---

## Security Configuration

| Attribute | Value | Standard |
|-----------|-------|---------|
| `associate_public_ip_address` | `false` | No public IP |
| `http_tokens` | `required` | IMDSv2 enforced — CKV_AWS_79 |
| `http_endpoint` | `enabled` | IMDS endpoint enabled, IMDSv2 only |
| `root_block_device.encrypted` | `true` | EBS root volume encrypted — CKV_AWS_8 |
| `ebs_optimized` | `true` | Optimized EBS throughput |
| `subnet_id` | App private subnet | Not deployed in public subnet |

---

## User Data

On first boot, user data automatically installs and runs Apache HTTP server:

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Three-Tier Architecture App Server $(hostname)</h1>" > /var/www/html/index.html
```

---

## Variables

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Project name |
| `environment` | `string` | Deployment environment (`dev`, `prod`) |
| `ami_id` | `string` | AMI ID — recommended: Amazon Linux 2023 |
| `instance_type` | `string` | Instance type (e.g. `t3.micro`) |
| `app_subnet_ids` | `list(string)` | App Subnet ID list — output from the `vpc` module |
| `app_security_group_id` | `string` | SG ID for EC2 — output from `security-group` module |
| `target_group_arn` | `string` | ALB Target Group ARN — output from the `alb` module |

> **Suggested AMI**: `ami-0543dbdaf4e114be7` (Amazon Linux 2) or `ami-0d105bf3c7d10a264` — verify the latest AMI for region `ap-southeast-1` before deploying.

---

## Outputs

| Name | Description |
|------|-------------|
| `instance_ids` | List of EC2 instance IDs |
| `private_ips` | List of private IPs per instance |
| `private_dns` | List of private DNS names per instance |
| `availability_zones` | List of AZs the instances are deployed in |

---

## Notes

- **EC2 vs ASG**: The `ec2` module creates static (fixed) instances, while the `autoscaling` module creates dynamic instances via Launch Template. Both register to the same Target Group. In production, prefer `autoscaling` for automatic scaling capability.
- **SSH**: No key pair is configured. Access instances via **AWS Systems Manager Session Manager** (no port 22 needed).
- **IAM Role**: `CKV2_AWS_41` is skipped. Production should attach an IAM Instance Profile to grant SSM, CloudWatch Agent, etc. permissions.
- **Monitoring**: `CKV_AWS_126` is skipped — Detailed Monitoring incurs additional cost; consider enabling for production.
