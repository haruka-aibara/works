# hcp-vault

HCP Vault Dedicated のクラスターを立て、AWS の VPC とピアリングするモジュール。
[HashiCorp のチュートリアル](https://developer.hashicorp.com/vault/tutorials/terraform-hcp-vault)をなぞったもの。

## コードの外にある前提

- hcp プロバイダーの認証は、`HCP_CLIENT_ID` / `HCP_CLIENT_SECRET` 環境変数で渡す。

## 気をつけること

- **ピア側の VPC は、渡した aws プロバイダーのリージョンに作られる。**
  `var.region` と揃える。
- **クラスターは `public_endpoint = true` で外から見える。**

## apply 後

HCP の画面で Cluster URLs の Public を押し、開いたリンクから Vault に入る。

![Cluster URLs](assets/memo/image-1.png)

![Vault のログイン画面](assets/memo/image.png)
