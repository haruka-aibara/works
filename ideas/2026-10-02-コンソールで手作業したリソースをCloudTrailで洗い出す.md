tags: aws, cloudtrail, duckdb, terraform, security

# コンソールで手作業したリソースを CloudTrail で洗い出す

Terraform で管理しているはずのアカウントに、コンソールで作られたリソースが混ざっていないかを CloudTrail で調べる。
いわゆる ClickOps の検出。

## 見分け方

CloudTrail のレコードには、コンソールのセッションから来た呼び出しかどうかが残る。

- `sessionCredentialFromConsole = "true"`
- `readOnly = false`（書き込み系だけに絞る）
- `eventName` が `Create*` / `Put*` / `Delete*` / `Modify*`

これで Terraform の実行ロールでも、AWS サービス自身でもない「人の手」の変更だけが残る。
DuckDB で手元に落としてあれば、SQL 1本で出る。

## 何に効くか

- ドリフトの予防：`terraform plan` は管理外のリソースを知らないので、管理外で増えたものは plan では見えない
- 緊急対応の事後確認：break-glass でコンソールに入った日の変更を、あとで全部コード化したか確かめる
- 人ごとの集計で「この人はまだコンソールで作っている」を責めずに把握し、IaC に寄せる相談の材料にする

関連：[CloudTrail は DuckDB で手元に落として掘る](./2026-09-29-CloudTrailはDuckDBで手元に落として掘る.md)
