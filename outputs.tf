output "ci_runner_role_arn" {
  value       = aws_iam_role.ci_runner.arn
  description = "ARN of the OIDC CI runner IAM role"
}

output "db_secret_arn" {
  value       = aws_secretsmanager_secret.db_password.arn
  description = "ARN of the database password secret"
}
