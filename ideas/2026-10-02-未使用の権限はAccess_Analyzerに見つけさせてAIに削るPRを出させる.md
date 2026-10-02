tags: aws, iam, access-analyzer, terraform, ai, security

# 未使用の権限は Access Analyzer に見つけさせて AI に削る PR を出させる

最小権限は「最初に絞る」より「使われていないものを後で削る」ほうが現実的。
Access Analyzer の未使用アクセス検出（unused access analyzer）は、
使っていないロール・アクセスキー・パスワード・サービスやアクションの権限を finding として出してくれる。

## 流れ

1. 人間が finding を JSON で落としてリポジトリに置く（AI は AWS に繋がない）
2. AI が該当する Terraform の IAM ポリシーを探し、削る PR を出す
3. 人間がマージ・apply。90 日など、検出期間より長く使われていない権限だけ対象にする

`modules/iam-access-analyzer-policy-generate` のポリシー生成は「CloudTrail から作る」方向、こちらは「今あるものから削る」方向で、組み合わせられる。

## 敵対的に見ると

- 年1回しか使わない権限（DR 手順・監査対応）も「未使用」になる。削る前に用途をタグかコメントで残す
- 未使用アクセス検出はロール・ユーザー単位の月額課金（料金は未確認）。対象アカウントを絞る
- 削って壊れたときに気づけるのは本番。まず `AccessDenied` を見る仕組みが要る
