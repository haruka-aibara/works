tags: aws, iam, vault, security

# IAM ユーザーのキーは、信頼ポリシーの代わりに IP 条件の Deny で使える場所を絞る

ロールなら信頼ポリシーの `aws:SourceIp` で AssumeRole の接続元を絞れる。IAM ユーザーのキーにはこの関所がない。
そこで IAM ユーザーには、**指定 IP 以外からの操作を全部拒否する Deny ポリシーを付ける。**

- `aws:SourceIp` が `NotIpAddress` なら `Action: "*"` を Deny
- 直接でもグループ経由でもよい。boundary に入れるなら Allow も併記する

元の権限によらず、キーは許可レンジ内でしか使えない。

## 例：Vault で発行する特権昇格用の IAM ユーザー

Vault の AWS secrets engine（`iam_user`）で作業時だけ発行する強い権限のユーザーにも付ける。
Deny を管理ポリシーにして、ロールの `policy_arns` に元の権限と並べれば、発行されるキー全部に効く。

## 穴になりそうなところ

- VPC エンドポイント経由では `aws:SourceIp` が付かず、Deny される。`aws:SourceVpc` などで例外にする
- AWS サービス経由の呼び出しも拒否される。`aws:ViaAWSService` で除く
- レンジ内から Deny を外したり条件なしのキーを作ったりはできる。防ぐならその操作も Deny する（[材料の権限を絞る](2026-10-03-権限昇格の経路は見つけるより材料の権限を絞る.md)）
