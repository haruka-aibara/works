tags: vault, aws, iam, security

# Vault で発行する IAMFullAccess のキーは、IP 条件の Deny を足して使える場所を絞る

Vault の AWS secrets engine（`iam_user`）で IAM 操作用のキーを発行するとき、
**`IAMFullAccess` はそのまま付け、指定 IP 以外を拒否する Deny を別に足す。**
明示的な Deny は Allow に勝つので、IAM 操作は特定の IP レンジからしかできなくなる。

Vault のロールは `policy_arns` と `policy_document` を同時に持てる。

- `policy_arns`：`IAMFullAccess`
- `policy_document`：`aws:SourceIp` が `NotIpAddress` なら `*` を Deny

ポリシーを自作でコピーしなくて済む。

## 穴になりそうなところ

- VPC エンドポイント経由では `aws:SourceIp` が効かない。`aws:SourceVpc` などで別に絞る
- AWS サービス経由の呼び出しも拒否される。`aws:ViaAWSService` で外す
- IAMFullAccess があれば、自分の Deny を外せるし、IP 条件のないユーザーやキーも作れる。
  `iam:DeleteUserPolicy` / `iam:CreateAccessKey` なども Deny に含めるか、permissions boundary で縛る（[材料の権限を絞る](2026-10-03-権限昇格の経路は見つけるより材料の権限を絞る.md)）
- Vault の `token_bound_cidrs` が絞るのはキーを取り出せる場所で、使える場所ではない。両方かける

自分自身への操作だけを Deny する書き方は未確認。
