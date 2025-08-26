output "vscode_server_cloudfront_domain_name" {
  description = "CloudFront distribution domain name for accessing code-server"
  value       = "https://${aws_cloudfront_distribution.vscode_server_cloudfront.domain_name}"
}

output "vscode_server_public_ip" {
  description = "Public IP address of the code-server instance"
  value       = aws_eip.vscode_server_eip.public_ip
}

output "vscode_server_private_ip" {
  description = "Private IP address of the code-server instance"
  value       = aws_instance.vscode_server.private_ip
}

output "vscode_server_instance_id" {
  description = "Instance ID of the code-server EC2 instance"
  value       = aws_instance.vscode_server.id
}

output "vscode_server_role_arn" {
  description = "ARN of the IAM role attached to the code-server instance"
  value       = aws_iam_role.vscode_server_iam_role.arn
}

output "vscode_server_password_ssm" {
  description = "SSM Parameter path containing the code-server password"
  value       = "/code-server/password"
}

output "password_retrieval_command" {
  description = "AWS CLI command to retrieve the code-server password"
  value       = "aws ssm get-parameter --name '/code-server/password' --with-decryption --region ${data.aws_region.current.name}"
}
