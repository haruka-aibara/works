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
- 組み合わせ（コンテナ × サプライチェーン）：ECR の pull-through cache で自動作成されるリポジトリに、repository creation template でタグ不変化やスキャンを強制する
- 組み合わせ（インシデント対応 × 組織）：Quarantine OU に SCP と RCP を付けておき、`MoveAccount` 1 回で隔離する
- 生成 AI：Bedrock Knowledge Bases は元の S3 の権限を越えて答えるので、メタデータフィルタをアプリ側で付ける
- 上限・クォータ：セキュリティ対応用の Lambda に reserved concurrency を確保する
- 組み合わせ（サプライチェーン × IAM）：GitHub OIDC の `sub` を名前だけで縛ると、改名・削除後に同じ名前を取られて入られるので、`repository_id` などの ID で縛る
- 組み合わせ（組織 × S3）：閉鎖したアカウントのバケット名を他人に取られるので、`aws:ResourceAccount` で自組織以外のバケットに書かせない
- 組み合わせ（生成 AI × データの所在）：Bedrock の cross-region inference でリージョン制限の SCP を越えるので、`jp.` の profile に限る
- インシデント対応の準備：`aws/ebs` で暗号化したスナップショットは共有できないので、EBS のデフォルトキーをフォレンジック用に許可した CMK にする
- 組み合わせ（人・組織 × 後片付け）：作成者タグを自動で付け、SCIM で退職者が無効化されたら Resource Explorer で洗い出して引き継ぐ
- 組み合わせ（証明書 × DNS）：Certificate Transparency ログの証明書名を Route 53 のレコードと突き合わせる
- 組み合わせ（IaC × 棚卸し）：`default_tags` の `managed-by` がないリソースを Resource Explorer で探す
- 攻撃の手口：`PowerUserAccess` なら EC2 Instance Connect でどのインスタンスにも SSH できる
- コスト：使っていないリージョンに $0.01 の Budgets を置いて SCP の抜けを確かめる
- 組み合わせ（秘密情報 × DB ログ）：ローテーション後に古いパスワードで認証失敗した相手を拾い、ハードコードや漏えいを見つける
- 組み合わせ（Security Hub × IaC × 時間）：automation rules の抑制を Terraform で管理し、期限切れを CI で落とす
- 組み合わせ（上限・クォータ × IAM）：信頼ポリシーの文字数上限でワイルドカードに逃げないよう、`aws:PrincipalOrgPaths` で書く
- 攻撃の手口：盗まれた鍵で SES から自社ドメインのフィッシングを送られる
- 仕組みの裏側：`GetSecretValue` や `GetParameter` は管理イベントなので、機微な小さいデータは S3 より読み取りの監査がただで付く
