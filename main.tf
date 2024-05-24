data "aws_caller_identity" "default" {
}

data "aws_region" "default" {
}

locals {
  cloudwatch_log_group_name = var.cloudwatch_log_group_name == "" ? "/aws/aes/domains/${var.domain_name}" : var.cloudwatch_log_group_name
}

resource "aws_security_group" "default" {
  count       = var.enabled && var.vpc_options != null ? 1 : 0
  vpc_id      = lookup(var.vpc_options, "vpc_id")
  name        = var.domain_name
  description = "Allow inbound traffic from Security Groups and CIDRs."
  tags = merge(
    {
      "Name" = var.domain_name
    },
    var.tags,
  )
}

resource "aws_security_group_rule" "ingress_security_groups" {
  count                    = var.enabled && var.vpc_options != null ? length(var.security_groups) : 0
  description              = "Allow inbound traffic from Security Groups"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.security_groups[count.index]
  security_group_id        = join("", aws_security_group.default.*.id)
}

resource "aws_security_group_rule" "ingress_cidr_blocks" {
  count             = var.enabled && var.vpc_options != null && length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  description       = "Allow inbound traffic from CIDR blocks"
  type              = "ingress"
  from_port         = 0
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = join("", aws_security_group.default.*.id)
}

resource "aws_security_group_rule" "egress" {
  count             = var.enabled && var.vpc_options != null ? 1 : 0
  description       = "Allow all egress traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.default.*.id)
}

resource "aws_cloudwatch_log_group" "cloudwatch" {
  count             = length(var.log_publishing_options) > 0 ? 1 : 0
  retention_in_days = var.cloudwatch_log_retention_in_days
  name              = local.cloudwatch_log_group_name
  tags              = var.tags
}

resource "aws_cloudwatch_log_resource_policy" "cloudwatch_policy" {
  count           = length(var.log_publishing_options) > 0 ? 1 : 0
  policy_name     = var.domain_name
  policy_document = data.aws_iam_policy_document.elasticsearch-log-publishing-policy.json
}

data "aws_iam_role" "default" {
  count = var.enabled && var.create_iam_service_linked_role == false ? 1 : 0
  name  = "AWSServiceRoleForAmazonOpenSearchService"
}

# https://github.com/terraform-providers/terraform-provider-aws/issues/5218
resource "aws_iam_service_linked_role" "default" {
  count            = var.enabled && var.create_iam_service_linked_role ? 1 : 0
  aws_service_name = "es.amazonaws.com"
  description      = "AWSServiceRoleForAmazonOpenSearchService Service-Linked Role"
}

# Role that pods can assume for access to elasticsearch and kibana
resource "aws_iam_role" "elasticsearch_user" {
  count              = var.enabled && (length(var.iam_authorizing_role_arns) > 0 || length(var.iam_role_arns) > 0) ? 1 : 0
  name               = "${var.domain_name}-service-role"
  assume_role_policy = join("", data.aws_iam_policy_document.assume_role.*.json)
  description        = "IAM Role to assume to access the Elasticsearch ${var.domain_name} cluster"
  tags               = var.tags
}

data "aws_iam_policy_document" "assume_role" {
  count = var.enabled && (length(var.iam_authorizing_role_arns) > 0 || length(var.iam_role_arns) > 0) ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = compact(concat(var.iam_authorizing_role_arns, var.iam_role_arns))
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "elasticsearch-log-publishing-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = ["${aws_cloudwatch_log_group.cloudwatch[0].arn}:*"]

    principals {
      identifiers = ["es.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "null_resource" "azs" {
  count = var.availability_zone_count > 1 ? 1 : 0
  triggers = {
    availability_zone_count = var.availability_zone_count
  }
}

resource "aws_elasticsearch_domain" "default" {
  count                 = var.enabled ? 1 : 0
  domain_name           = var.domain_name
  elasticsearch_version = var.elasticsearch_version
  advanced_options      = var.advanced_options

  ebs_options {
    ebs_enabled = var.ebs_volume_size > 0 ? true : false
    volume_size = var.ebs_volume_size
    volume_type = var.ebs_volume_type
    iops        = var.ebs_iops
  }

  encrypt_at_rest {
    enabled    = var.encrypt_at_rest_enabled
    kms_key_id = var.encrypt_at_rest_kms_key_id
  }

  domain_endpoint_options {
    enforce_https                   = var.domain_endpoint_options_enforce_https
    tls_security_policy             = var.domain_endpoint_options_tls_security_policy
    custom_endpoint_enabled         = var.custom_endpoint_enabled
    custom_endpoint                 = var.custom_endpoint_enabled ? var.custom_endpoint : null
    custom_endpoint_certificate_arn = var.custom_endpoint_enabled ? var.custom_endpoint_certificate_arn : null
  }

  cluster_config {
    instance_count           = var.instance_count
    instance_type            = var.instance_type
    dedicated_master_enabled = var.dedicated_master_enabled
    dedicated_master_count   = var.dedicated_master_count
    dedicated_master_type    = var.dedicated_master_type
    zone_awareness_enabled   = var.zone_awareness_enabled
    dynamic "zone_awareness_config" {
      for_each = null_resource.azs[*].triggers
      content {
        availability_zone_count = zone_awareness_config.value.availability_zone_count
      }
    }
  }

  node_to_node_encryption {
    enabled = var.node_to_node_encryption_enabled
  }

  dynamic "vpc_options" {
    for_each = var.vpc_options == null ? [] : [var.vpc_options]
    content {
      security_group_ids = [aws_security_group.default[0].id]
      subnet_ids         = vpc_options.value.subnet_ids
    }
  }

  snapshot_options {
    automated_snapshot_start_hour = var.automated_snapshot_start_hour
  }

  dynamic "log_publishing_options" {
    for_each = var.log_publishing_options
    content {
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.cloudwatch[0].arn
      enabled                  = lookup(log_publishing_options.value, "enabled", null)
      log_type                 = log_publishing_options.value.log_type
    }
  }

  advanced_security_options {
    enabled                        = var.advanced_security_options_enabled
    internal_user_database_enabled = var.advanced_security_options_internal_user_database_enabled
    master_user_options {
      master_user_arn      = var.advanced_security_options_master_user_arn
      master_user_name     = var.advanced_security_options_master_user_name
      master_user_password = var.advanced_security_options_master_user_password
    }
  }

  auto_tune_options {
    desired_state       = var.auto_tune_options_desired_state
    rollback_on_disable = var.auto_tune_options_rollback_on_disable

    dynamic "maintenance_schedule" {
      #for_each = var.auto_tune_options_maintenance_schedule
      for_each = length(keys(var.auto_tune_options_maintenance_schedule)) == 0 ? [] : [var.auto_tune_options_maintenance_schedule]
      content {
        cron_expression_for_recurrence = lookup(maintenance_schedule.value, "cron_expression_for_recurrence")
        start_at                       = lookup(maintenance_schedule.value, "start_at")

        dynamic "duration" {
          for_each = [lookup(maintenance_schedule.value, "duration")]
          content {
            unit  = lookup(duration.value, "unit")
            value = lookup(duration.value, "value")
          }
        }
      }
    }
  }
  tags       = var.tags
  depends_on = [aws_iam_service_linked_role.default]
}

data "aws_iam_policy_document" "default" {
  count = var.enabled && (length(var.iam_authorizing_role_arns) > 0 || length(var.iam_role_arns) > 0) ? 1 : 0

  statement {
    actions = distinct(compact(var.iam_actions))

    resources = [
      "${join("", aws_elasticsearch_domain.default.*.arn)}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = distinct(compact(concat(var.iam_role_arns, aws_iam_role.elasticsearch_user.*.arn)))
    }
  }
}

resource "aws_elasticsearch_domain_policy" "default" {
  count           = var.enabled && (length(var.iam_authorizing_role_arns) > 0 || length(var.iam_role_arns) > 0) && length(var.access_policies) == 0 ? 1 : 0
  domain_name     = var.domain_name
  access_policies = join("", data.aws_iam_policy_document.default.*.json)
}

resource "aws_elasticsearch_domain_policy" "custom" {
  count           = var.enabled && (length(var.iam_authorizing_role_arns) == 0 || length(var.iam_role_arns) == 0) && length(var.access_policies) > 0 ? 1 : 0
  domain_name     = var.domain_name
  access_policies = var.access_policies
}
