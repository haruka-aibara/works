output "github_actions_role_arn" {
  description = "Role the workflow assumes via GitHub OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "sns_topic_arn" {
  description = "Topic the workflow publishes the ideas to"
  value       = aws_sns_topic.this.arn
}
