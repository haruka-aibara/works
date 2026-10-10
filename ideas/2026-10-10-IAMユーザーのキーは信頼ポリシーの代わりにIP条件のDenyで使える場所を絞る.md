tags: aws, iam, vault, security

# IAM ユーザーのキーは、信頼ポリシーの代わりに IP 条件の Deny で使える場所を絞る

ロールは信頼ポリシーの `aws:SourceIp` で接続元を絞れるが、IAM ユーザーには信頼ポリシーがない。
そこで IAM ユーザーには、**指定 IP 以外からの操作を全部拒否する Deny ポリシーを付ける。**

- `aws:SourceIp` が `NotIpAddress` なら `Action: "*"` を Deny
- インライン・グループ・boundary のどれで付けてもよい

元の権限によらず、キーは許可レンジの中でしか使えなくなる。

## 例：Vault で発行する特権昇格用の IAM ユーザー

Vault の AWS secrets engine（`iam_user`）で作業時だけ発行する強い権限のユーザーにも付ける。
`policy_arns` に元の権限、`policy_document` に Deny を入れれば、発行されるキー全部に効く。

`token_bound_cidrs` が絞るのはキーを取り出せる場所で、使える場所ではない。両方かける。

## 穴になりそうなところ

- VPC エンドポイント経由では `aws:SourceIp` が効かない
- AWS サービス経由の呼び出しも拒否される。`aws:ViaAWSService` で外す
- IAM の権限があれば自分の Deny を外せる。その操作も Deny するか boundary で縛る（[材料の権限を絞る](2026-10-03-権限昇格の経路は見つけるより材料の権限を絞る.md)）
