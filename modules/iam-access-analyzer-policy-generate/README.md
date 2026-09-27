# iam-access-analyzer-policy-generate

IAM Access Analyzer のポリシー生成を試すためのモジュール。

旧リポジトリ `iam-access-analyzer-policy-generate` を履歴ごと取り込んだもの。
過去の経緯は `git log -- modules/iam-access-analyzer-policy-generate` で辿れる。

## apply 後

ポリシー生成そのものは Terraform ではやらない。
apply 後にコンソールか `aws accessanalyzer start-policy-generation` で、作成したサービスロールと証跡を指定して実行する。
