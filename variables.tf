variable "domain_name" {
  type        = string
  description = "Name of the domain"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

variable "security_groups" {
  type        = list(string)
  default     = []
  description = "List of security group IDs to be allowed to connect to the cluster"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "List of CIDR blocks to be allowed to connect to the cluster"
}

variable "ingress_from_port" {
  type        = number
  default     = 0
  description = "First TCP port allowed by the security group ingress rules."

  validation {
    condition     = var.ingress_from_port >= 0 && var.ingress_from_port <= 65535
    error_message = "ingress_from_port must be between 0 and 65535."
  }
}

variable "ingress_to_port" {
  type        = number
  default     = 443
  description = "Last TCP port allowed by the security group ingress rules."

  validation {
    condition     = var.ingress_to_port >= 0 && var.ingress_to_port <= 65535
    error_message = "ingress_to_port must be between 0 and 65535."
  }
}

variable "vpc_options" {
  description = "List of maps of options for publishing slow logs to CloudWatch Logs."
  type = object({
    vpc_id     = string
    subnet_ids = list(string)
  })
  default = null
}

variable "elasticsearch_version" {
  type        = string
  default     = "7.1"
  description = "Version of Elasticsearch to deploy"
}

variable "instance_type" {
  type        = string
  default     = "t2.small.elasticsearch"
  description = "Elasticsearch instance type for data nodes in the cluster"
}

variable "instance_count" {
  description = "Number of data nodes in the cluster"
  type        = any
  default     = 1
}

variable "iam_role_arns" {
  type        = list(string)
  default     = []
  description = "List of IAM role ARNs to permit access to the Elasticsearch domain"
}

variable "iam_authorizing_role_arns" {
  type        = list(string)
  default     = []
  description = "List of IAM role ARNs to permit to assume the Elasticsearch user role"
}

variable "iam_actions" {
  type        = list(string)
  default     = []
  description = "List of actions to allow for the IAM roles, _e.g._ `es:ESHttpGet`, `es:ESHttpPut`, `es:ESHttpPost`"
}

variable "access_policies" {
  description = "(Optional) IAM policy document specifying the access policies for the domain"
  type        = string
  default     = ""
}

variable "zone_awareness_enabled" {
  type        = bool
  default     = false
  description = "Enable zone awareness for Elasticsearch cluster"
}

variable "availability_zone_count" {
  type        = number
  default     = 1
  description = "Number of Availability Zones for the domain to use."
}

variable "ebs_volume_size" {
  description = "Optionally use EBS volumes for data storage by specifying volume size in GB"
  type        = any
  default     = 10
}

variable "ebs_volume_type" {
  type        = string
  default     = "gp2"
  description = "Storage type of EBS volumes"
}

variable "ebs_iops" {
  type        = any
  default     = 0
  description = "The baseline input/output (I/O) performance of EBS volumes attached to data nodes. Applicable only for the Provisioned IOPS EBS volume type"
}

variable "ebs_throughput" {
  type        = number
  default     = null
  description = "Throughput in MiB/s for gp3 EBS volumes. Leave null for non-gp3 volumes or to preserve the provider default."

  validation {
    condition     = var.ebs_throughput == null || var.ebs_throughput >= 125
    error_message = "ebs_throughput must be null or at least 125 MiB/s."
  }
}

variable "encrypt_at_rest_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable encryption at rest"
}

variable "encrypt_at_rest_kms_key_id" {
  type        = string
  default     = ""
  description = "The KMS key id to encrypt the Elasticsearch domain with. If not specified, then it defaults to using the AWS/Elasticsearch service KMS key"
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "Cloudwatch log group custom name, if not specified using '/aws/aes/domains/var.domain_name/'"
  default     = ""
}

variable "cloudwatch_log_retention_in_days" {
  type        = number
  description = "Cloudwatch logs retention days"
  default     = 30
}

variable "log_publishing_options" {
  description = "List of maps of options for publishing slow logs to CloudWatch Logs."
  type        = list(map(string))
  default     = []
}

variable "automated_snapshot_start_hour" {
  type        = any
  description = "Hour at which automated snapshots are taken, in UTC"
  default     = 0
}

variable "dedicated_master_enabled" {
  type        = bool
  default     = false
  description = "Indicates whether dedicated master nodes are enabled for the cluster"
}

variable "dedicated_master_count" {
  type        = any
  description = "Number of dedicated master nodes in the cluster"
  default     = 0
}

variable "dedicated_master_type" {
  type        = string
  default     = "t2.small.elasticsearch"
  description = "Instance type of the dedicated master nodes in the cluster"
}

variable "advanced_options" {
  type        = map(string)
  default     = {}
  description = "Key-value string pairs to specify advanced configuration options"
}

variable "create_iam_service_linked_role" {
  type        = bool
  default     = true
  description = "Whether to create `AWSServiceRoleForAmazonElasticsearchService` service-linked role. Set it to `false` if you already have an ElasticSearch cluster created in the AWS account and AWSServiceRoleForAmazonElasticsearchService already exists."
}

variable "service_linked_role_name" {
  type        = string
  default     = "AWSServiceRoleForAmazonOpenSearchService"
  description = "ANameRN of an IAM role that Elasticsearch service can assume to access the VPC resources"
}

variable "node_to_node_encryption_enabled" {
  type        = string
  default     = "false"
  description = "Whether to enable node-to-node encryption"
}

variable "domain_endpoint_options_enforce_https" {
  description = "Whether or not to require HTTPS"
  default     = false
  type        = bool
}

variable "domain_endpoint_options_tls_security_policy" {
  description = "The name of the TLS security policy that needs to be applied to the HTTPS endpoint"
  default     = "Policy-Min-TLS-1-2-2019-07"
  type        = string
}

variable "advanced_security_options_enabled" {
  type        = bool
  default     = false
  description = "AWS Elasticsearch Kibana enchanced security plugin enabling (forces new resource)"
}

variable "advanced_security_options_internal_user_database_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable or not internal Kibana user database for ELK OpenDistro security plugin"
}

variable "advanced_security_options_master_user_arn" {
  type        = string
  default     = ""
  description = "ARN of IAM user who is to be mapped to be Kibana master user (applicable if advanced_security_options_internal_user_database_enabled set to false)"
}

variable "advanced_security_options_master_user_name" {
  type        = string
  default     = ""
  description = "Master user username (applicable if advanced_security_options_internal_user_database_enabled set to true)"
}

variable "advanced_security_options_master_user_password" {
  type        = string
  default     = ""
  description = "Master user password (applicable if advanced_security_options_internal_user_database_enabled set to true)"
}

variable "custom_endpoint_enabled" {
  type        = bool
  description = "Whether to enable custom endpoint for the Elasticsearch domain."
  default     = false
}

variable "custom_endpoint" {
  type        = string
  description = "Fully qualified domain for custom endpoint."
  default     = ""
}

variable "custom_endpoint_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for custom endpoint."
  default     = ""
}

variable "auto_tune_options_desired_state" {
  type        = string
  description = "(Required) The Auto-Tune desired state for the domain. Valid values: ENABLED or DISABLED."
  default     = "DISABLED"
}

variable "auto_tune_options_rollback_on_disable" {
  type        = string
  description = "(Optional) Whether to roll back to default Auto-Tune settings when disabling Auto-Tune. Valid values: DEFAULT_ROLLBACK or NO_ROLLBACK."
  default     = null
}

variable "auto_tune_options_maintenance_schedule" {
  type        = any
  description = "(Required if rollback_on_disable is set to DEFAULT_ROLLBACK) Configuration block for Auto-Tune maintenance windows."
  default     = {}
}
