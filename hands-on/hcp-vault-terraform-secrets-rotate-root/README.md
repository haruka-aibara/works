# hcp-vault-terraform-secrets-rotate-root

HCP Vault Dedicated の HCP Terraform secrets engine に team token を root token として渡し、
`rotate-root` と自動ローテーション（`rotation_period`）を試すための最小構成。

works ワークスペースでは apply しない。手元でローカル state のまま apply して、試し終わったら destroy する。

## コードの外にある前提

- HCP Terraform の組織が有料プランであること。Free では owners 以外の team を作れない
- Vault が 2.2.0 以上であること。secrets engine に `rotate-root` が入ったのがこのバージョン
- 自動ローテーションは Enterprise 機能（Rotation Manager）。HCP Vault Dedicated は Enterprise なので、dev tier でも動く想定
- 環境変数で `HCP_CLIENT_ID` / `HCP_CLIENT_SECRET` / `TFE_TOKEN` を渡す

## 手順

team が無いと token を発行できないので、apply を 2 回に分ける。

1. `terraform apply -target=tfe_team.vault -target=hcp_vault_cluster_admin_token.this`
2. output の `vault_version` が 2.2.0 以上か見る。足りなければ rotate-root も自動ローテーションも使えない
3. HCP Terraform の UI で `vault-root` team の token を発行する
4. `TF_VAR_bootstrap_team_token=<発行した token> terraform apply`
5. `vault write -f terraform/rotate-root` を叩く。UI で手で発行した token が消え、Vault が発行した token に入れ替わっていれば成功
6. `vault read terraform/config` の `next_vault_rotation` を過ぎたら、もう一度 UI で token が入れ替わっているのを見る

Vault が token を回したあとも、apply で token は送り直されない。
`token_wo_version` を上げたときだけ `bootstrap_team_token` で上書きされる。

## 片付け

dev tier でも時間課金なので `terraform destroy` する。
Vault が発行した token は Terraform の管理外だが、team と一緒に消える。
