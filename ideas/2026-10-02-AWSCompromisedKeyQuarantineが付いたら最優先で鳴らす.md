tags: aws, iam, eventbridge, security, incident-response

# AWSCompromisedKeyQuarantine が付いたら最優先で鳴らす

アクセスキーが GitHub 等の公開場所に漏れているのを AWS が見つけると、
AWS がそのユーザーに `AWSCompromisedKeyQuarantineV2/V3` 系のマネージドポリシーを自動で付ける（はず）。
これは「AWS のほうが先に漏えいに気づいた」という意味で、人間が気づくより早い。

**この付与（`AttachUserPolicy`）を EventBridge で拾って最優先で鳴らす**。
Health イベントやサポートからのメールより早く、確実に人間に届けたい。

## 気をつけること

- 付けられるポリシーは一部の操作を Deny するだけで、キーは生きたまま。初動は [クレデンシャル漏洩後の初動対応](../docs/Amazon%20Web%20Services/04_セキュリティ/IAM/クレデンシャル漏洩後の初動対応.md) のとおり無効化から
- 誰かが「邪魔だから」とポリシーを外す（`DetachUserPolicy`）のも同じく鳴らす
- そもそも IAM ユーザーのアクセスキーを減らすのが本筋。これは残ってしまったキーへの保険

ポリシー名のバージョンと自動付与の条件は公式ドキュメント未確認。
