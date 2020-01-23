module "elasticsearch-CLIENTE-es" {
  source                             = "git::https://gitlab.com/ganex-cloud/terraform/terraform-aws-elasitcsearch.git?ref=master"
  domain_name                        = "CLIENTE-es"
  security_groups                    = ["sg-xxxxx"]
  vpc_id                             = "vpc-xxxxx"
  subnet_ids                         = ["subnet-xxxx", "subnet-xxxx"]
  zone_awareness_enabled             = "false"
  elasticsearch_version              = "5.3"
  instance_type                      = "t2.small.elasticsearch"
  instance_count                     = 2
  iam_role_arns                      = ["arn:aws:iam::111111111111:user/TEST"]
  iam_actions                        = ["es:ESHttpGet", "es:ESHttpPut", "es:ESHttpPost"]
  log_publishing_index_enabled       = "true"
  log_publishing_search_enabled      = "true"
  log_publishing_application_enabled = "true"
}
