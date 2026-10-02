tags: aws, iam, oidc, terraform, hcp-terraform, security

# HCP Terraform に渡しているロールの信頼ポリシーを見直す

このリポジトリは HCP Terraform の動的認証（OIDC）で AWS に入っている。
IAM の OIDC プロバイダーとロールは手で作ったので、**信頼ポリシーの `sub` 条件がどうなっているかコードから分からない**。

OIDC のロールは、`sub` を絞り忘れると「同じ発行元のトークンなら誰でも入れる」状態になる。
HCP Terraform の発行元 `app.terraform.io` も全利用者で共通なので、構図は同じ。

## 見ること

- `aud` が `aws.workload.identity` になっているか
- `sub` が `organization:<自分の org>:project:<project>:workspace:<workspace>:run_phase:*` まで絞られているか
- org だけ絞ってワークスペースを `*` にしていると、同じ org の別ワークスペースからも入れる
- plan と apply でロールを分けるなら `run_phase` で分ける。plan 用は読み取り専用にできる

## ついでに

手で作ったものは、`import` ブロックで Terraform に取り込むと信頼ポリシーがレビュー対象になる。
ただし自分自身が使うロールを自分で管理すると、ミスした apply で締め出される。取り込むなら別 state か、`prevent_destroy` を付ける。

条件の書式は公式ドキュメントで要確認。
