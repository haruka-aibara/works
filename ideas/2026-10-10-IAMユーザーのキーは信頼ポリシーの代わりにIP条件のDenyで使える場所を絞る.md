tags: aws, iam, vault, security

# IAM ユーザーのキーは、信頼ポリシーの代わりに IP 条件の Deny で使える場所を絞る

ロールなら、信頼ポリシーの `aws:SourceIp` で引き受けられる接続元を絞れる。
IAM ユーザーには信頼ポリシーがない。

代わりに、**指定 IP 以外からの操作を全部拒否する Deny を、ユーザーに付ける。**
Deny は Allow に勝つので、元の権限によらずキーは許可レンジの中でしか使えない。
付け方はインライン・グループ・permissions boundary のどれでもよい。

Vault の AWS secrets engine（`iam_user`）で発行するキーも同じ。
`policy_arns` に元の権限、`policy_document` にこの Deny を入れれば、発行されるキー全部に効く。

## 穴になりそうなところ

- VPC エンドポイント経由では `aws:SourceIp` が効かない。`aws:SourceVpc` などで別に絞る
- AWS サービス経由の呼び出しも拒否される。`aws:ViaAWSService` で外す
- IAM の権限があれば、自分の Deny を外したり、条件のないキーを作ったりできる。
  その操作も Deny するか boundary で縛る（[材料の権限を絞る](2026-10-03-権限昇格の経路は見つけるより材料の権限を絞る.md)）
- Vault の `token_bound_cidrs` が絞るのはキーを取り出せる場所で、使える場所ではない。両方かける
