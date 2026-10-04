# security-ideas-slack-notifier

`.github/workflows/security-ideas.yml` が出したセキュリティのアイデアを、Slack に届けるための AWS 側のモジュール。

## コードの外にある前提

- Slack ワークスペースは、事前に AWS Chatbot のコンソールで認可しておく。
- Bedrock のモデルアクセスは、ワークフローの `BEDROCK_MODEL` のモデルについて、推論プロファイルが転送する全リージョンで有効にしておく。
- ワークフローはロールとトピックの ARN を直書きしている。Terraform の state をワークフローから読めないため。
