tags: terraform, hcp-terraform, secrets, security

# Terraform の state に残る秘密を棚卸しする

`sensitive = true` は plan の表示を隠すだけで、**state には平文で残る**。
Terraform 1.11 以降は、write-only 引数（`value_wo` など）と ephemeral を使えば state に載せずに済む。

このリポジトリでも `bedrock-slack-ai-chatbot` の SSM パラメータは `value_wo` で外している。
残りを棚卸しする。

## 秘密は 2 種類ある

| 種類 | 例 | state から外せるか |
|---|---|---|
| 外から入れる秘密 | Slack のトークン、GitHub App の PEM | write-only 引数があれば外せる |
| Terraform が作る秘密 | `random_password`、`aws_iam_access_key`、`tfe_team_token` | ephemeral リソースで作って write-only で渡せるものは外せる。リソースの属性として返ってくるものは外せない |

## 見るところ

- `tfe_variable` の `set-in-ui` は、値を UI で入れて state に載せない回避策。provider に `value_wo` があれば素直に書ける
- `tfe-team-token-rotation` のトークンは、Terraform が発行する以上 state に残る（コメントにもそう書いてある）。外せない秘密は、state を読める人を絞る側で守る
- RDS のマスターパスワードは、`manage_master_user_password` で AWS に作らせれば state に載らない

`tfe_variable` に `value_wo` があるかは未確認。
