# AWS-Three-Tier-Architecture

## Thành phần:
- Presentation Tier (Web Layer)
    + Public Subnet
    + Application Load Balancer (ALB)
    + EC2 Web Servers
- Application Tier
    + Private Subnet
    + EC2 Application Servers
    + Auto Scaling Group
- Data Tier
    + Private Subnet
    + Database (MySQL/PostgreSQL trên RDS)
- Thành phần bổ sung:
    + VPC
    + Internet Gateway
    + NAT Gateway
    + Route Tables
    + Security Groups
    + IAM
    + CloudWatch

### Kiến trúc cuối:
```bash
Internet
    ↓
Application Load Balancer
    ↓
Web Tier (EC2 Public)
    ↓
App Tier (EC2 Private)
    ↓
Database Tier (RDS Private)
```
---


