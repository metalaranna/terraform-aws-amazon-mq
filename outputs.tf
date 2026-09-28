output "broker_id" {
  description = "ID of the Amazon MQ broker."
  value       = aws_mq_broker.this.id
}

output "broker_arn" {
  description = "ARN of the Amazon MQ broker."
  value       = aws_mq_broker.this.arn
}

output "endpoints" {
  description = "Broker connection endpoints (protocol-specific URLs)."
  value       = aws_mq_broker.this.instances[*].endpoints
}

output "console_url" {
  description = "Web console URL for the broker."
  value       = try(aws_mq_broker.this.instances[0].console_url, null)
}

output "security_group_id" {
  description = "Security group protecting the broker."
  value       = aws_security_group.this.id
}

output "credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the generated admin credentials (null if you supplied your own password)."
  value       = try(aws_secretsmanager_secret.broker[0].arn, null)
}
