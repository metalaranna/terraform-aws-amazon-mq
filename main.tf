provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Project   = var.name
        ManagedBy = "terraform"
      },
      var.tags
    )
  }
}

# ---------------------------------------------------------------------------
# Credentials: use the supplied password, or generate one and store it in
# Secrets Manager so it never has to live in a .tfvars file or state diff.
# ---------------------------------------------------------------------------
resource "random_password" "admin" {
  count = var.admin_password == null ? 1 : 0

  length  = 24
  special = true
  # ActiveMQ/RabbitMQ both reject a handful of characters in passwords.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  admin_password = coalesce(var.admin_password, try(random_password.admin[0].result, null))
}

resource "aws_secretsmanager_secret" "broker" {
  count = var.admin_password == null ? 1 : 0

  name        = "${var.name}-mq-credentials"
  description = "Amazon MQ admin credentials for ${var.name}"
}

resource "aws_secretsmanager_secret_version" "broker" {
  count = var.admin_password == null ? 1 : 0

  secret_id = aws_secretsmanager_secret.broker[0].id
  secret_string = jsonencode({
    username = var.admin_username
    password = local.admin_password
  })
}

# ---------------------------------------------------------------------------
# Network access
# ---------------------------------------------------------------------------
locals {
  # ActiveMQ: OpenWire 61617, console 8162. RabbitMQ: AMQPS 5671, console 443.
  broker_ports = var.engine_type == "RabbitMQ" ? [5671, 443] : [61617, 8162]
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "Access to the ${var.engine_type} broker"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "broker" {
  for_each = {
    for pair in setproduct(var.allowed_cidr_blocks, local.broker_ports) :
    "${pair[0]}-${pair[1]}" => { cidr = pair[0], port = pair[1] }
  }

  security_group_id = aws_security_group.this.id
  description       = "Broker port ${each.value.port} from ${each.value.cidr}"
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "audit" {
  count             = var.audit_log_enabled ? 1 : 0
  name              = "/aws/amazonmq/${var.name}/audit"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "general" {
  count             = var.general_log_enabled ? 1 : 0
  name              = "/aws/amazonmq/${var.name}/general"
  retention_in_days = 30
}

# ---------------------------------------------------------------------------
# Broker
# ---------------------------------------------------------------------------
resource "aws_mq_broker" "this" {
  broker_name = var.name

  engine_type        = var.engine_type
  engine_version     = var.engine_version
  host_instance_type = var.host_instance_type
  deployment_mode    = var.deployment_mode

  subnet_ids          = var.subnet_ids
  security_groups     = [aws_security_group.this.id]
  publicly_accessible = var.publicly_accessible

  user {
    username = var.admin_username
    password = local.admin_password
  }

  encryption_options {
    use_aws_owned_key = true
  }

  logs {
    audit   = var.audit_log_enabled
    general = var.general_log_enabled
  }

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  tags = {
    Name = var.name
  }

  depends_on = [
    aws_cloudwatch_log_group.audit,
    aws_cloudwatch_log_group.general,
  ]
}
