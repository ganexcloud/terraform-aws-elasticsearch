module "elasticsearch" {
  source = "../../"

  domain_name                    = "elasticsearch-example"
  enabled                        = false
  create_iam_service_linked_role = false
  tags = {
    Example = "complete"
  }
}
