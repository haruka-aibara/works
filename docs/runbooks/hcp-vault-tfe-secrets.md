# HCP Vault の HCP Terraform secrets engine（team token の rotate-root）

**この文書を読むとき:** secrets engine を立ち上げるとき。Vault が持つ root token を手で回したいとき。片付けるとき。

**3行:**

- HCP Vault Dedicated（`module.hcp_vault`）に HCP Terraform secrets engine を載せ、`vault-root` team の token を root token として渡す
- Vault は `rotation_period`（既定 1 時間）ごとに自分でその token を作り直し、古い方を消す。Terraform は最初の 1 回しか token を渡さない
- 動かすには HCP Terraform の有料プラン（owners 以外の team が要る）と Vault 2.2.0 以上が要る

---

## 1. 立ち上げ

team が無いと token を発行できず、token が無いと secrets engine を設定できないので、PR を 2 本に分ける。

1. works ワークスペースに `HCP_CLIENT_ID` / `HCP_CLIENT_SECRET` を env 変数（sensitive）で入れる。**マージ前にやる。** 無いと apply が HCP の認証で落ちる
2. `configure_secrets_engine = false` のまま main にマージする。クラスター・`vault-root` team・変数 `hcp_vault_tfe_bootstrap_team_token`（中身は `set-in-ui`）ができる
3. HCP の画面でクラスターの Vault のバージョンが 2.2.0 以上か見る。足りなければ rotate-root も自動ローテーションも使えない
4. HCP Terraform の UI で `vault-root` team の token を発行し、変数 `hcp_vault_tfe_bootstrap_team_token` の値に入れる
5. `main.tf` の `configure_secrets_engine` を `true` にした PR をマージする

## 2. 確かめる

`vault` CLI は次の 3 つを設定して使う。admin token は HCP の画面でクラスターから発行する。

- `VAULT_ADDR`: クラスターの Public URL
- `VAULT_NAMESPACE`: `admin`
- `VAULT_TOKEN`: admin token

確かめること:

- `vault write -f terraform/rotate-root` を実行して、UI で手で発行した token が消え、Vault が発行した token（description が `Vault Terraform secrets engine root token` で始まる）に入れ替わるか
- `vault read terraform/config` に出る `next_vault_rotation` の時刻を過ぎたあと、もう一度 token が入れ替わるか

ローテーションのあとに works の apply が走っても、token は送り直されない。
`token_wo_version` を上げたときだけ、そのときの変数の値で上書きされる。

## 3. 片付け

dev tier でも時間課金なので、試し終わったら止める。

1. `configure_secrets_engine` を `false` にしてマージする。secrets engine を消すのに `provider "vault"` が要るので、先にこれだけ消す
2. `main.tf` の `module "hcp_vault_tfe_secrets"` と `module "hcp_vault"`、`tfe_variable.hcp_vault_tfe_bootstrap_team_token`、`providers.tf` の `provider "vault"` をコメントアウトしてマージする

Vault が発行した token は Terraform の管理外だが、team と一緒に消える。
