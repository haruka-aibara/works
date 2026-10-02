tags: aws, iam, terraform, ransomware, security

# 書き込みは Terraform の実行ロールだけにする

盗んだクレデンシャルの手口を 1 つずつ Deny していくと終わらない。
逆にして、**書き込みできるのは Terraform の実行ロールだけ**にする。

- 人間は ReadOnly。書き込みは break-glass のロールだけ
- アプリはそのアプリが使う操作だけ
- 守るのは実行ロール 1 つ。OIDC の信頼条件とブランチ保護に集中する
- Terraform の外の変更は [差分の通知](2026-10-02-Terraformの差分が出たら鳴らす.md) で拾う

## それでも Deny するもの

Terraform ですら使わない操作だけ。組織なら SCP で。

| 手口 | Deny するもの |
|---|---|
| 自分の鍵（SSE-C）で上書きして身代金 | SSE-C ヘッダー付きの `s3:PutObject` |
| 持ち込んだ鍵素材で暗号化し直し、消して身代金 | `kms:KeyOrigin` が `EXTERNAL` の `kms:CreateKey` |
| 通信をミラーリングして盗聴 | `ec2:CreateTrafficMirrorSession` |

## 覚えておくこと

- スナップショット・AMI・RDS・バケットポリシーは、公開ブロックがあっても**アカウントを名指しする共有**は通る。組織なら RCP で `aws:PrincipalOrgID` に絞る
- 検知サービスを止められたときは [別経路で鳴らす](2026-10-02-検知サービスを止める操作はDenyして別経路で鳴らす.md)

条件キーと RCP の対応範囲は未確認。
