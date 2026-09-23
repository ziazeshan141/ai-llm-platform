# ---------------------------------------------------------
# ECR Repository URLs
# ---------------------------------------------------------

output "repository_urls" {
  description = "Map of service names to ECR repository URLs."

  value = {
    for service, repository in aws_ecr_repository.this :
    service => repository.repository_url
  }
}


# ---------------------------------------------------------
# ECR Repository ARNs
# ---------------------------------------------------------

output "repository_arns" {
  description = "Map of service names to ECR repository ARNs."

  value = {
    for service, repository in aws_ecr_repository.this :
    service => repository.arn
  }
}


# ---------------------------------------------------------
# ECR Repository Names
# ---------------------------------------------------------

output "repository_names" {
  description = "Map of service names to ECR repository names."

  value = {
    for service, repository in aws_ecr_repository.this :
    service => repository.name
  }
}