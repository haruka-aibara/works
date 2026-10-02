tags: aws, cloudtrail, terraform, duckdb, security, operations

# コンソール手作業の変更を CloudTrail から月 1 で洗い出す

Terraform で管理しているはずの環境に、コンソールからの手作業（ClickOps）が混ざる。
drift として `plan` で見えるのは Terraform 管理下のリソースだけで、管理外に作られたものは見えない。

CloudTrail を見れば、人がコンソールから書き込んだ操作は全部拾える。

## 抜き出す条件

- `readOnly = false`（書き込み系だけ）
- `sessionCredentialFromConsole = "true"`、または `userAgent` が Terraform でない
- `userIdentity.sessionContext.sessionIssuer.userName` が `AWSReservedSSO_*`（Identity Center 経由の人間）

これを [DuckDB で手元に落とした証跡](2026-09-29-CloudTrailはDuckDBで手元に落として掘る.md) に投げて、イベント名 × 人 × 回数で並べる。

## 通知はしない

月 1 で手元で掘るだけにする。
見るのは「誰が何を繰り返し手でやっているか」。
繰り返しているものは Terraform か Runbook に吸い上げる候補で、[件数の多いアラートを予防で潰す](2026-09-26-通知が多いセキュリティアラートを予防で減らす.md) のと同じ発想。

## 未確認

- `sessionCredentialFromConsole` がどのサービスのイベントでも確実に入るか
- CloudShell から叩いた CLI がコンソール扱いになるか
