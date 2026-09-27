tags: aws, cloudtrail, terraform, hcp-terraform, cli, operations

# 手で変えたドリフトは lookup-events で犯人を探す

HCP Terraform のドリフト検知（health assessments）は Standard 以上の機能。Free にはない。
代わりに、plan に「覚えのない差分」が出たときだけ、CloudTrail を手元で引く。

```sh
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ReadOnly,AttributeValue=false \
  --start-time 2026-09-20 \
  | jq '.Events[] | .CloudTrailEvent | fromjson
        | select(.userIdentity.arn | test("<Terraform実行ロール名>") | not)
        | {eventTime, eventName, arn: .userIdentity.arn}'
```

- `--lookup-attributes` に指定できる条件は1つだけ。書き込みで絞ってから、Terraform の実行ロールを jq で除く
- 見られるのは直近90日の管理イベントだけ。ドリフトに気づくのが遅れると追えない
- 除いたあとに残るのは、コンソールや手元の CLI、AWS 側の自動処理

[CloudTrail 検索は Amazon Q より手元で lookup-events](2026-09-26-CloudTrail検索はAmazon_Qより手元でlookup-eventsを叩くほうがいいのでは.md) の具体的な使いどころになる。
AI にこのコマンドを組ませるなら、実行は人がやる。

## 未確認

HCP Terraform の dynamic credentials で AssumeRole したときのセッション名の形式（jq の除外条件に使えるか）。
