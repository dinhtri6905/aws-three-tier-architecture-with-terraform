# ===== MODULE: VPC =====
module "vpc" {
  source = "../../modules/vpc"
}

# ===== MODULE: SECURITY GROUP =====
module "security-group" {
  source = "../../modules/security-group"
}

# ===== MODULE: EC2 =====
module "ec2" {
  source = "../../modules/ec2"
}

