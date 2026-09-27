# aws-budget-slack-notifier

AWS Budgets の日次コストが閾値を超えたら、Slack に通知するモジュール。

参考記事: https://zenn.dev/takehiro1111/articles/budget_slack_notify

## なぜこの作りか

- **SNS トピックと KMS キーは us-east-1 に作る。**
  Budgets が us-east-1 のサービスだから。
  そのため、呼び出し側から `aws` と `aws.us-east-1` の 2 つのプロバイダーを渡す。

## コードの外にある前提

- Slack ワークスペースは、事前に AWS Chatbot のコンソールで認可しておく。
