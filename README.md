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

### Integrated GitHub Actions CI/CD pipeline with:
- TFLint for Terraform linting
- tfsec for infrastructure security scanning
- Checkov for CIS compliance validation
- OPA/Rego for policy-as-code enforcement

```bash
| Tool     | Vai trò trong CI/CD                                                                    |
| -------- | -------------------------------------------------------------------------------------- |
| TFLint   | Kiểm tra Terraform syntax, AWS best practice, phát hiện cấu hình sai                   |
| tfsec    | Quét lỗi bảo mật cho Infrastructure as Code                                            |
| Checkov  | Quét security và compliance, hỗ trợ nhiều framework như AWS Foundations, NIST, PCI DSS |
| OPA/Rego | Policy as Code, tự định nghĩa quy tắc và chính sách tổ chức                            |

```