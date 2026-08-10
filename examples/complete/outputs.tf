output "domain_name" {
  description = "Example Elasticsearch domain name."
  value       = module.elasticsearch.domain_name
}

output "domain_arn" {
  description = "Example Elasticsearch domain ARN."
  value       = module.elasticsearch.domain_arn
}
