output "instance_profile_name" {
  description = "Name of the IAM Instance Profile for App/Web EC2 instances and the ASG Launch Template"
  value       = aws_iam_instance_profile.app_instance.name
}

output "instance_profile_arn" {
  description = "ARN of the IAM Instance Profile"
  value       = aws_iam_instance_profile.app_instance.arn
}

output "role_name" {
  description = "Name of the IAM Role attached to the instance profile"
  value       = aws_iam_role.app_instance.name
}

output "role_arn" {
  description = "ARN of the IAM Role attached to the instance profile"
  value       = aws_iam_role.app_instance.arn
}
