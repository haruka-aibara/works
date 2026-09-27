# iam-access-analyzer-policy-generate

IAM Access Analyzer のポリシー生成を試すためのモジュール。

## apply 後

ポリシー生成そのものは Terraform ではやらない。
apply 後にコンソールか `aws accessanalyzer start-policy-generation` で、作成したサービスロールと証跡を指定して実行する。
