# Module: VPC

Creates the entire network infrastructure for the three-tier architecture on AWS, including the VPC, per-tier subnets, Internet Gateway, NAT Gateways per AZ, and corresponding Route Tables.

---

## Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_vpc` | 1 | Main VPC with DNS support and DNS hostnames enabled |
| `aws_internet_gateway` | 1 | Internet Gateway attached to the VPC |
| `aws_subnet` (public) | N (per AZ) | Public subnets for ALB and NAT Gateways |
| `aws_subnet` (app) | N (per AZ) | Private App subnets for EC2 and ASG |
| `aws_subnet` (db) | N (per AZ) | Private DB subnets — no internet route |
| `aws_eip` | N (per AZ) | Elastic IP for each NAT Gateway |
| `aws_nat_gateway` | N (per AZ) | NAT Gateway per AZ — High Availability |
| `aws_route_table` (public) | 1 | Route `0.0.0.0/0` → Internet Gateway |
| `aws_route_table` (app) | N (per AZ) | Route `0.0.0.0/0` → respective NAT Gateway |
| `aws_route_table` (db) | 1 | No internet route |

---

## Network Design

```
VPC (10.0.0.0/16)
│
├── Public Subnets (10.0.1.0/24 · 10.0.2.0/24 · 10.0.3.0/24)
│   ALB · NAT-GW-1 · NAT-GW-2 · NAT-GW-3
│
├── App Private Subnets (10.0.11.0/24 · 10.0.12.0/24 · 10.0.13.0/24)
│   EC2 Application Servers · ASG
│
└── DB Private Subnets (10.0.21.0/24 · 10.0.22.0/24 · 10.0.23.0/24)
    RDS MySQL / PostgreSQL
```

**Traffic separation:**
- **Public Subnet**: `map_public_ip_on_launch = true` — for ALB and NAT Gateways
- **App Subnet**: Tier tag = `Application`, no public IP, outbound internet via AZ-local NAT Gateway
- **DB Subnet**: Tier tag = `Database`, fully isolated, no internet route

---

## Variables

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Project name — used to name resources |
| `environment` | `string` | Deployment environment (`dev`, `prod`) |
| `vpc_cidr` | `string` | VPC CIDR block (e.g. `10.0.0.0/16`) |
| `availability_zones` | `list(string)` | List of AZs — determines the number of subnets and NAT Gateways |
| `public_subnet_cidrs` | `list(string)` | CIDRs for Public Subnets, must match the number of AZs |
| `app_subnet_cidrs` | `list(string)` | CIDRs for App Subnets, must match the number of AZs |
| `db_subnet_cidrs` | `list(string)` | CIDRs for DB Subnets, must match the number of AZs |

---

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID — used as input for other modules |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_ids` | List of Public Subnet IDs — input for `alb` module |
| `app_subnet_ids` | List of App Subnet IDs — input for `ec2`, `autoscaling` modules |
| `db_subnet_ids` | List of DB Subnet IDs — input for `rds` module |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `app_route_table_ids` | List of App tier Route Table IDs |
| `db_route_table_id` | DB tier Route Table ID |

---

## Notes

- **NAT Gateway per AZ**: The module creates one NAT Gateway per AZ to ensure High Availability. This increases cost but eliminates a single point of failure.
- **Checkov skip**: `CKV2_AWS_11` (VPC Flow Logs) and `CKV2_AWS_12` (Default SG) are skipped for lab — production should enable VPC Flow Logs.
- The number of subnets and NAT Gateways depends on `length(var.availability_zones)` — no code changes needed when adding an AZ.
# Module: VPC

Creates the entire network infrastructure for the three-tier architecture on AWS, including the VPC, per-tier subnets, Internet Gateway, NAT Gateways per AZ, and corresponding Route Tables.

---

## Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_vpc` | 1 | Main VPC with DNS support and DNS hostnames enabled |
| `aws_internet_gateway` | 1 | Internet Gateway attached to the VPC |
| `aws_subnet` (public) | N (per AZ) | Public subnets for ALB and NAT Gateways |
| `aws_subnet` (app) | N (per AZ) | Private App subnets for EC2 and ASG |
| `aws_subnet` (db) | N (per AZ) | Private DB subnets — no internet route |
| `aws_eip` | N (per AZ) | Elastic IP for each NAT Gateway |
| `aws_nat_gateway` | N (per AZ) | NAT Gateway per AZ — High Availability |
| `aws_route_table` (public) | 1 | Route `0.0.0.0/0` → Internet Gateway |
| `aws_route_table` (app) | N (per AZ) | Route `0.0.0.0/0` → respective NAT Gateway |
| `aws_route_table` (db) | 1 | No internet route |

---

## Network Design

```
VPC (10.0.0.0/16)
│
├── Public Subnets (10.0.1.0/24 · 10.0.2.0/24 · 10.0.3.0/24)
│   ALB · NAT-GW-1 · NAT-GW-2 · NAT-GW-3
│
├── App Private Subnets (10.0.11.0/24 · 10.0.12.0/24 · 10.0.13.0/24)
│   EC2 Application Servers · ASG
│
└── DB Private Subnets (10.0.21.0/24 · 10.0.22.0/24 · 10.0.23.0/24)
    RDS MySQL / PostgreSQL
```

**Traffic separation:**
- **Public Subnet**: `map_public_ip_on_launch = true` — for ALB and NAT Gateways
- **App Subnet**: Tier tag = `Application`, no public IP, outbound internet via AZ-local NAT Gateway
- **DB Subnet**: Tier tag = `Database`, fully isolated, no internet route

---

## Variables

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Project name — used to name resources |
| `environment` | `string` | Deployment environment (`dev`, `prod`) |
| `vpc_cidr` | `string` | VPC CIDR block (e.g. `10.0.0.0/16`) |
| `availability_zones` | `list(string)` | List of AZs — determines the number of subnets and NAT Gateways |
| `public_subnet_cidrs` | `list(string)` | CIDRs for Public Subnets, must match the number of AZs |
| `app_subnet_cidrs` | `list(string)` | CIDRs for App Subnets, must match the number of AZs |
| `db_subnet_cidrs` | `list(string)` | CIDRs for DB Subnets, must match the number of AZs |

---

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID — used as input for other modules |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_ids` | List of Public Subnet IDs — input for `alb` module |
| `app_subnet_ids` | List of App Subnet IDs — input for `ec2`, `autoscaling` modules |
| `db_subnet_ids` | List of DB Subnet IDs — input for `rds` module |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `app_route_table_ids` | List of App tier Route Table IDs |
| `db_route_table_id` | DB tier Route Table ID |

---

## Notes

- **NAT Gateway per AZ**: The module creates one NAT Gateway per AZ to ensure High Availability. This increases cost but eliminates a single point of failure.
- **Checkov skip**: `CKV2_AWS_11` (VPC Flow Logs) and `CKV2_AWS_12` (Default SG) are skipped for lab — production should enable VPC Flow Logs.
- The number of subnets and NAT Gateways depends on `length(var.availability_zones)` — no code changes needed when adding an AZ.
