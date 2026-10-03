tags: terraform, hcp-terraform, secrets, security

# Terraform の state に残る秘密を棚卸しする

`sensitive = true` は plan の表示を隠すだけで、**state には平文で残る**。
Terraform 1.11 以降は、write-only 引数（`value_wo` など）と ephemeral を使えば state に載せずに済む。

## 秘密は 2 種類ある

| 種類 | 例 | state から外せるか |
|---|---|---|
| 外から入れる秘密 | API トークン、秘密鍵、DB のパスワード | write-only 引数があれば外せる |
| Terraform が作る秘密 | `random_password`、`aws_iam_access_key`、`tfe_team_token` | ephemeral リソースで作って write-only で渡せるものは外せる。リソースの属性として返ってくるものは外せない |

## 見るところ

- SSM パラメータや Secrets Manager に値を入れるリソースは、write-only 引数に置き換えられるものが多い
- 「値はあとで UI や CLI から入れる」というダミー値の回避策は、provider に write-only 引数があれば素直に書ける
- アクセスキーや API トークンを Terraform で発行すると、state に残るのは避けられない。外せない秘密は、state を読める人を絞る側で守る
- RDS のマスターパスワードは、`manage_master_user_password` で AWS に作らせれば state に載らない

provider ごとの write-only 引数の対応範囲は未確認。
