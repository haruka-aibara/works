tags: vault, aws, terraform, security

# Vault AWS secrets engine の IAM ユーザーはローテーション設定で回せる

HCP Vault の AWS secrets engine が使う IAM ユーザーのアクセスキーは、
secrets engine のパラメーター（`rotation_period` / `rotation_schedule`）で Vault に自動ローテーションさせられる。
Terraform では `vault_aws_secret_backend` に同名の引数がある。使えるかは Vault と provider のバージョンを確認する。
