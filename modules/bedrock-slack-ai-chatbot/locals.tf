locals {
  # Resource naming. default_tags (Owner/Environment/Project/Repository) come
  # from the root module's aws.bedrock_slack_ai_chatbot provider, passed in as
  # this module's default aws provider.
  project_name = "bedrock-slack-ai-chatbot"
}
