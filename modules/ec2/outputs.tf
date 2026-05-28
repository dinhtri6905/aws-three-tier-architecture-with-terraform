output "instance_ids" {
    description = "EC2 Instance IDs"
    value       = aws_instance.app[*].id
}

output "private_ips" {
description = "Private IP addresses of EC2 instances"
    value       = aws_instance.app[*].private_ip
}

output "private_dns" {
    description = "Private DNS names of EC2 instances"
    value       = aws_instance.app[*].private_dns
}

output "availability_zones" {
    description = "Availability Zones of EC2 instances"
    value       = aws_instance.app[*].availability_zone
}
