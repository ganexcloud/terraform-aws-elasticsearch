module "elasticsearch" {
  source = "../../"

  domain_name                    = "opensearch-example"
  enabled                        = false
  create_iam_service_linked_role = false
  elasticsearch_version          = "OpenSearch_3.7"
  instance_type                  = "t3.small.search"
  ebs_volume_type                = "gp3"
  ebs_volume_size                = 30
  ebs_iops                       = 3000
  ebs_throughput                 = 125
  ingress_from_port              = 443
  ingress_to_port                = 443
  tags = {
    Example = "complete"
  }
}
