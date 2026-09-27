tags: aws, cloudtrail, amazon-q, ai, cli

# CloudTrail 検索は Amazon Q より手元で lookup-events を叩くほうがいいのでは

Amazon Q（コンソール）と CloudTrail の統合で、自然言語で CloudTrail を検索できるようになった。
ただ、AI がある今なら、`aws cloudtrail lookup-events` を手元でこねて叩くほうが developer 目線ではいいのでは、と思っている。

Amazon Q を使うなら料金や利用方針を決める必要がある。それなら単に CLI のほうがいいのでは。

## どこまで掘れるか

| 掘りたいもの | Q（コンソール） | 手元 CLI |
|---|---|---|
| 直近 90 日の管理イベント | ○（イベント履歴） | ○（`lookup-events`） |
| 90 日より前・データイベント | CloudWatch Logs に送っていれば○（取り込み料金が別にかかる） | Athena で S3 を直接検索 |
| S3 にしかないログ | × | ○（Athena） |

AWS Cloud Operations Blog「Investigate your AWS account activity in plain language with Amazon Q」（2026/9/15）の内容を AI 経由で聞いたもの。ブログ本文はまだ自分で確認していない。
