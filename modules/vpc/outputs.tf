output "vpc_id" {
description = "VPC ID"
value       = aws_vpc.main.id
}

output "internet_gateway_id" {
description = "Internet Gateway ID"
value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
description = "Public Subnet IDs"
value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
description = "Application Subnet IDs"
value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
description = "Database Subnet IDs"
value       = aws_subnet.db[*].id
}

output "nat_gateway_ids" {
description = "NAT Gateway IDs"
value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
description = "Public Route Table ID"
value       = aws_route_table.public.id
}

output "app_route_table_ids" {
description = "Application Route Table IDs"
value       = aws_route_table.app[*].id
}

output "db_route_table_id" {
description = "Database Route Table ID"
value       = aws_route_table.db.id
}
