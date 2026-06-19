# Module: Monitoring

Creates a comprehensive monitoring system for the three-tier architecture, including CloudWatch Alarms, SNS notifications, CloudWatch Log Groups, and a CloudWatch Dashboard.

---

## Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_sns_topic` | 1 | Topic for receiving and distributing alerts |
| `aws_sns_topic_subscription` | 0 or 1 | Email subscription (if `sns_email` is set) |
| `aws_cloudwatch_metric_alarm` | 8 | Alarms for App tier, Data tier, and Web tier |
| `aws_cloudwatch_log_group` | 2 | Log groups for Web tier and App tier |
| `aws_cloudwatch_dashboard` | 1 | Dashboard aggregating 5 charts |

---

## Alarms

### App Tier (ASG)

| Alarm | Condition | Action |
|-------|-----------|--------|
| `asg-cpu-high` | CPU > `asg_cpu_high_threshold`% for 2 × 5-minute periods | SNS alert |
| `asg-cpu-low` | CPU < `asg_cpu_low_threshold`% for 2 × 5-minute periods | SNS alert |

### Data Tier (RDS)

| Alarm | Condition | Action |
|-------|-----------|--------|
| `rds-cpu-high` | CPU > `rds_cpu_high_threshold`% for 2 × 5-minute periods | SNS alert |
| `rds-free-storage-low` | Free storage < `rds_free_storage_threshold` bytes for 2 periods | SNS alert |
| `rds-connections-high` | Connections > `rds_connections_threshold` for 2 periods | SNS alert |

### Web Tier (ALB)

| Alarm | Condition | Action |
|-------|-----------|--------|
| `alb-5xx-high` | HTTP 5xx > `alb_5xx_threshold` per minute × 2 periods | SNS alert |
| `alb-response-time-high` | Response time > `alb_response_time_threshold`s per minute × 3 periods | SNS alert |
| `alb-unhealthy-hosts` | UnhealthyHostCount > 0 per minute × 2 periods | SNS alert |

---

## Log Groups

| Log Group | Retention | Description |
|-----------|-----------|-------------|
| `/aws/ec2/{env}/app` | `log_retention_days` days | EC2 App tier logs |
| `/aws/ec2/{env}/web` | `log_retention_days` days | Web tier logs |

---

## CloudWatch Dashboard

A dashboard is automatically created with 5 time-series charts:

```
┌─────────────────────────┬──────────────────────────┐
│   ASG CPU Utilization   │   RDS CPU Utilization    │
├─────────────────────────┼──────────────────────────┤
│   RDS Free Storage      │   ALB Request Count      │
├─────────────────────────┴──────────────────────────┤
│              ALB Response Time                      │
└────────────────────────────────────────────────────┘
```

The dashboard URL is exported via the `dashboard_url` output.

---

## Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Project name |
| `environment` | `string` | Deployment environment |
| `aws_region` | `string` | AWS Region — used in Dashboard links |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `sns_email` | `string` | `""` | Email address for alerts. Leave empty to disable. |

### App Tier (ASG)

| Name | Type | Description |
|------|------|-------------|
| `autoscaling_group_name` | `string` | ASG name — output from `autoscaling` module |
| `asg_cpu_high_threshold` | `number` | CPU high threshold (%) — e.g. `80` |
| `asg_cpu_low_threshold` | `number` | CPU low threshold (%) — e.g. `20` |

### Data Tier (RDS)

| Name | Type | Description |
|------|------|-------------|
| `rds_instance_id` | `string` | RDS instance ID — output from `rds` module |
| `rds_cpu_high_threshold` | `number` | RDS CPU threshold (%) — e.g. `80` |
| `rds_free_storage_threshold` | `number` | Free storage threshold (bytes) — e.g. `5368709120` (5 GB) |
| `rds_connections_threshold` | `number` | Max concurrent connections threshold — e.g. `100` |

### Web Tier (ALB)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `alb_arn_suffix` | `string` | — | ALB ARN suffix — output from `alb` module |
| `target_group_arn_suffix` | `string` | — | Target Group ARN suffix — output from `alb` module |
| `alb_5xx_threshold` | `number` | `10` | Number of 5xx errors per minute before alarm |
| `alb_response_time_threshold` | `number` | — | Maximum response time (seconds) — e.g. `2` |

### Log Retention

| Name | Type | Description |
|------|------|-------------|
| `log_retention_days` | `number` | Number of days to retain logs. Valid values: 1, 3, 5, 7, 14, 30, 60, 90... |

---

## Outputs

| Name | Description |
|------|-------------|
| `sns_topic_arn` | SNS topic ARN |
| `sns_topic_name` | SNS topic name |
| `asg_cpu_high_alarm_name` | ASG CPU high alarm name |
| `asg_cpu_low_alarm_name` | ASG CPU low alarm name |
| `rds_cpu_alarm_name` | RDS CPU alarm name |
| `rds_free_storage_alarm_name` | RDS storage alarm name |
| `rds_connections_alarm_name` | RDS connections alarm name |
| `alb_5xx_alarm_name` | ALB 5xx alarm name |
| `alb_response_time_alarm_name` | ALB response time alarm name |
| `alb_unhealthy_hosts_alarm_name` | ALB unhealthy hosts alarm name |
| `app_log_group_name` | App tier Log Group name |
| `web_log_group_name` | Web tier Log Group name |
| `dashboard_name` | CloudWatch Dashboard name |
| `dashboard_url` | Console URL for viewing the Dashboard |

---

## Notes

- **SNS Email confirmation**: After deployment, AWS sends a confirmation email to `sns_email`. You must click "Confirm subscription" to start receiving alerts.
- **rds_free_storage_threshold**: The unit is **bytes**, not GB. `5 GB = 5 * 1024^3 = 5368709120`.
- **Dashboard URL**: Use the `dashboard_url` output to open the Dashboard directly in the AWS Console.
- **OPA compliance**: `compliance.rego` will warn if no `aws_cloudwatch_metric_alarm` exists for unauthorized API calls — consider adding a CIS 4.1 alarm.
# Module: Monitoring

Creates a comprehensive monitoring system for the three-tier architecture, including CloudWatch Alarms, SNS notifications, CloudWatch Log Groups, and a CloudWatch Dashboard.

---

## Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_sns_topic` | 1 | Topic for receiving and distributing alerts |
| `aws_sns_topic_subscription` | 0 or 1 | Email subscription (if `sns_email` is set) |
| `aws_cloudwatch_metric_alarm` | 8 | Alarms for App tier, Data tier, and Web tier |
| `aws_cloudwatch_log_group` | 2 | Log groups for Web tier and App tier |
| `aws_cloudwatch_dashboard` | 1 | Dashboard aggregating 5 charts |

---

## Alarms

### App Tier (ASG)

| Alarm | Condition | Action |
|-------|-----------|--------|
| `asg-cpu-high` | CPU > `asg_cpu_high_threshold`% for 2 × 5-minute periods | SNS alert |
| `asg-cpu-low` | CPU < `asg_cpu_low_threshold`% for 2 × 5-minute periods | SNS alert |

### Data Tier (RDS)

| Alarm | Condition | Action |
|-------|-----------|--------|
| `rds-cpu-high` | CPU > `rds_cpu_high_threshold`% for 2 × 5-minute periods | SNS alert |
| `rds-free-storage-low` | Free storage < `rds_free_storage_threshold` bytes for 2 periods | SNS alert |
| `rds-connections-high` | Connections > `rds_connections_threshold` for 2 periods | SNS alert |

### Web Tier (ALB)

| Alarm | Condition | Action |
|-------|-----------|--------|
| `alb-5xx-high` | HTTP 5xx > `alb_5xx_threshold` per minute × 2 periods | SNS alert |
| `alb-response-time-high` | Response time > `alb_response_time_threshold`s per minute × 3 periods | SNS alert |
| `alb-unhealthy-hosts` | UnhealthyHostCount > 0 per minute × 2 periods | SNS alert |

---

## Log Groups

| Log Group | Retention | Description |
|-----------|-----------|-------------|
| `/aws/ec2/{env}/app` | `log_retention_days` days | EC2 App tier logs |
| `/aws/ec2/{env}/web` | `log_retention_days` days | Web tier logs |

---

## CloudWatch Dashboard

A dashboard is automatically created with 5 time-series charts:

```
┌─────────────────────────┬──────────────────────────┐
│   ASG CPU Utilization   │   RDS CPU Utilization    │
├─────────────────────────┼──────────────────────────┤
│   RDS Free Storage      │   ALB Request Count      │
├─────────────────────────┴──────────────────────────┤
│              ALB Response Time                      │
└────────────────────────────────────────────────────┘
```

The dashboard URL is exported via the `dashboard_url` output.

---

## Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Project name |
| `environment` | `string` | Deployment environment |
| `aws_region` | `string` | AWS Region — used in Dashboard links |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `sns_email` | `string` | `""` | Email address for alerts. Leave empty to disable. |

### App Tier (ASG)

| Name | Type | Description |
|------|------|-------------|
| `autoscaling_group_name` | `string` | ASG name — output from `autoscaling` module |
| `asg_cpu_high_threshold` | `number` | CPU high threshold (%) — e.g. `80` |
| `asg_cpu_low_threshold` | `number` | CPU low threshold (%) — e.g. `20` |

### Data Tier (RDS)

| Name | Type | Description |
|------|------|-------------|
| `rds_instance_id` | `string` | RDS instance ID — output from `rds` module |
| `rds_cpu_high_threshold` | `number` | RDS CPU threshold (%) — e.g. `80` |
| `rds_free_storage_threshold` | `number` | Free storage threshold (bytes) — e.g. `5368709120` (5 GB) |
| `rds_connections_threshold` | `number` | Max concurrent connections threshold — e.g. `100` |

### Web Tier (ALB)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `alb_arn_suffix` | `string` | — | ALB ARN suffix — output from `alb` module |
| `target_group_arn_suffix` | `string` | — | Target Group ARN suffix — output from `alb` module |
| `alb_5xx_threshold` | `number` | `10` | Number of 5xx errors per minute before alarm |
| `alb_response_time_threshold` | `number` | — | Maximum response time (seconds) — e.g. `2` |

### Log Retention

| Name | Type | Description |
|------|------|-------------|
| `log_retention_days` | `number` | Number of days to retain logs. Valid values: 1, 3, 5, 7, 14, 30, 60, 90... |

---

## Outputs

| Name | Description |
|------|-------------|
| `sns_topic_arn` | SNS topic ARN |
| `sns_topic_name` | SNS topic name |
| `asg_cpu_high_alarm_name` | ASG CPU high alarm name |
| `asg_cpu_low_alarm_name` | ASG CPU low alarm name |
| `rds_cpu_alarm_name` | RDS CPU alarm name |
| `rds_free_storage_alarm_name` | RDS storage alarm name |
| `rds_connections_alarm_name` | RDS connections alarm name |
| `alb_5xx_alarm_name` | ALB 5xx alarm name |
| `alb_response_time_alarm_name` | ALB response time alarm name |
| `alb_unhealthy_hosts_alarm_name` | ALB unhealthy hosts alarm name |
| `app_log_group_name` | App tier Log Group name |
| `web_log_group_name` | Web tier Log Group name |
| `dashboard_name` | CloudWatch Dashboard name |
| `dashboard_url` | Console URL for viewing the Dashboard |

---

## Notes

- **SNS Email confirmation**: After deployment, AWS sends a confirmation email to `sns_email`. You must click "Confirm subscription" to start receiving alerts.
- **rds_free_storage_threshold**: The unit is **bytes**, not GB. `5 GB = 5 * 1024^3 = 5368709120`.
- **Dashboard URL**: Use the `dashboard_url` output to open the Dashboard directly in the AWS Console.
- **OPA compliance**: `compliance.rego` will warn if no `aws_cloudwatch_metric_alarm` exists for unauthorized API calls — consider adding a CIS 4.1 alarm.
