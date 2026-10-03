# ボツ案

ユーザーに刺さらなかったアイデア。
同じネタも、同じ切り口の言い換えも出さない。

1 行 1 本で、日付・種類・中身の順に書く。
理由がわかっていれば `—` のあとに書く。

## 日付不明

- ハニートークン：使わないアクセスキーを撒いて、使われたら検知する

## 2026-10-03

- 組み合わせ（ID 連携）：IdP から `SourceIdentity` を渡し、信頼ポリシーで `sts:SourceIdentity` を必須にして、ロールチェーンの先でも「誰が」を残す
- 組み合わせ（IaC × 時間）：Terraform の `check` ブロック（証明書の期限・Public Access Block）を HCP Terraform の continuous validation で定期評価する
- 組み合わせ（ネットワーク × CI）：VPC Network Access Analyzer の scope を apply 後の CI で流し、到達してはいけない経路があれば失敗させる
- 攻撃の手口：KMS キーに `ScheduleKeyDeletion` をかけて脅す。キーポリシーで禁止し、EventBridge で通知する
- 仕組みの裏側：停止中の EC2 の userData に `#cloud-boothook` を仕込み、起動のたびに実行させて永続化する
- 組み合わせ（IaC × 人・組織）：plan の JSON で IAM・キーポリシー・バケットポリシーの変更を見つけ、セキュリティ担当のレビューを必須にする
- 組み合わせ（設計・DR × 時間）：AWS Backup の logically air-gapped vault と Restore testing で、消されないことと戻せることを毎月確かめる
- 組み合わせ（上限・クォータ）：`RequestServiceQuotaIncrease` を SCP で禁止して通知し、GPU マイニングの予兆に気づく
- 攻撃の手口（端末）：IAM Identity Center の device code フローを使ったフィッシング
- 時間がたつと危なくなる：Lambda のランタイム終了で更新がブロックされ、緊急のパッチを当てられなくなる
- 組み合わせ（ネットワーク × 組織）：RAM で共有したマネージドプレフィックスリストを 1 行変えると組織中の SG が開くので、SCP で変更を絞って通知する
- 組み合わせ（生成 AI × 端末）：コーディングエージェント用の権限セットにセッションタグを付け、SCP で書き込みを拒否する
- 攻撃の手口：Session Manager のリモートホストへのポートフォワーディングで、どのインスタンスも踏み台になる
- 仕組みの裏側：KMS の grant はキーポリシーから外しても残るので、`CreateGrant` を見張って棚卸しする
