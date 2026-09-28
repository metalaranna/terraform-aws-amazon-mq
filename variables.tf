variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name of the Amazon MQ broker."
  type        = string
  default     = "app-broker"
}

variable "engine_type" {
  description = "Broker engine: ActiveMQ or RabbitMQ."
  type        = string
  default     = "ActiveMQ"

  validation {
    condition     = contains(["ActiveMQ", "RabbitMQ"], var.engine_type)
    error_message = "engine_type must be either \"ActiveMQ\" or \"RabbitMQ\"."
  }
}

variable "engine_version" {
  description = "Broker engine version. Check `aws mq describe-broker-engine-types` for currently supported versions."
  type        = string
  default     = "5.18.6"
}

variable "host_instance_type" {
  description = "Broker instance type, e.g. mq.t3.micro, mq.m5.large."
  type        = string
  default     = "mq.t3.micro"
}

variable "deployment_mode" {
  description = "SINGLE_INSTANCE, ACTIVE_STANDBY_MULTI_AZ (ActiveMQ), or CLUSTER_MULTI_AZ (RabbitMQ)."
  type        = string
  default     = "SINGLE_INSTANCE"

  validation {
    condition     = contains(["SINGLE_INSTANCE", "ACTIVE_STANDBY_MULTI_AZ", "CLUSTER_MULTI_AZ"], var.deployment_mode)
    error_message = "deployment_mode must be SINGLE_INSTANCE, ACTIVE_STANDBY_MULTI_AZ, or CLUSTER_MULTI_AZ."
  }
}

variable "vpc_id" {
  description = "VPC to deploy the broker into."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the broker. One subnet for SINGLE_INSTANCE; two (in different AZs) for ACTIVE_STANDBY_MULTI_AZ. Use private subnets."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "Provide at least one subnet ID."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the broker's console and protocol ports (e.g. your app subnets)."
  type        = list(string)

  validation {
    condition     = length(var.allowed_cidr_blocks) > 0 && !contains(var.allowed_cidr_blocks, "0.0.0.0/0")
    error_message = "Provide at least one CIDR block, and do not open the broker to 0.0.0.0/0."
  }
}

variable "publicly_accessible" {
  description = "Whether the broker gets a public endpoint. Keep false unless you have a specific reason."
  type        = bool
  default     = false
}

variable "admin_username" {
  description = "Broker admin username."
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Broker admin password. Leave null to auto-generate and store in Secrets Manager instead of passing a plaintext value here."
  type        = string
  default     = null
  sensitive   = true
}

variable "auto_minor_version_upgrade" {
  description = "Allow AWS to apply minor engine version upgrades automatically."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply configuration changes immediately instead of during the next maintenance window. Can cause a brief broker restart."
  type        = bool
  default     = false
}

variable "audit_log_enabled" {
  description = "Enable audit logging to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "general_log_enabled" {
  description = "Enable general logging to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
