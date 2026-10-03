# ボツ案

ユーザーに刺さらなかったアイデア。
同じネタも、同じ切り口の言い換えも出さない。

1 行 1 本で、日付・種類・中身の順に書く。
理由がわかっていれば `—` のあとに書く。

## 2026-10-03

- 組み合わせ（ID 連携）：IdP から `SourceIdentity` を渡し、信頼ポリシーで `sts:SourceIdentity` を必須にして、ロールチェーンの先でも「誰が」を残す
- 組み合わせ（IaC × 時間）：Terraform の `check` ブロック（証明書の期限・Public Access Block）を HCP Terraform の continuous validation で定期評価する
- 組み合わせ（ネットワーク × CI）：VPC Network Access Analyzer の scope を apply 後の CI で流し、到達してはいけない経路があれば失敗させる
- 攻撃の手口：KMS キーに `ScheduleKeyDeletion` をかけて脅す。キーポリシーで禁止し、EventBridge で通知する
- 仕組みの裏側：停止中の EC2 の userData に `#cloud-boothook` を仕込み、起動のたびに実行させて永続化する
