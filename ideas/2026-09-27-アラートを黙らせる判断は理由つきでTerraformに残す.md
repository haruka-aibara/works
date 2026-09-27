tags: aws, security-hub, guardduty, terraform, audit, operations

# アラートを黙らせる判断は理由つきで Terraform に残す

Security Hub CSPM のコントロールの無効化も、GuardDuty の抑制ルールも、コンソールで押せばすぐ済む。
ただそうすると「誰がいつ、なぜ黙らせたか」が残らない。
監査で聞かれても答えられない。

- Security Hub CSPM: `aws_securityhub_standards_control_association` で `association_status = "DISABLED"` にする。この場合 `updated_reason` が必須なので、理由を書かないと apply できない
- GuardDuty: `aws_guardduty_filter` の `action = "ARCHIVE"` で抑制ルールにする。抑制した検出結果は EventBridge にも流れないので、通知も止まる

PR にすれば、黙らせる判断そのものがレビューを通り、履歴に残る。
[通知が多いアラートを予防で減らす](2026-09-26-通知が多いセキュリティアラートを予防で減らす.md) で「予防より通知を止めるほうが早い」ものの置き場所になる。

## 注意

- 古い `aws_securityhub_standards_control` ではなく、新しい association のほうを使う
- 抑制ルールは条件を広く書くと、本物の検出まで消える。finding type だけでなく、リソースやアカウントまで絞る
