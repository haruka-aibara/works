tags: aws, cloudtrail, duckdb, athena, security

# CloudTrail は DuckDB で手元に落として掘る

`lookup-events` の次の一手。
S3 の証跡を `aws s3 sync` で手元に落とし、DuckDB で SQL を投げる。
一度落とせば、何回掘っても AWS の料金はかからない。

## Athena との正直な比較

- クエリごとの課金は規模を問わず気になる。組織はログが多くて試行錯誤が請求に積み上がり、個人はそもそも払いたくない
- DuckDB なら払うのはダウンロードの1回だけ。準備なしで始められて、何度でも試せる
- ログが TB 単位で手元に落としきれないなら、Athena で絞る1回だけ課金して結果を落とし、DuckDB で掘る
- 手元のコピーは証拠にならない。監査で使うのは S3 の原本（Object Lock・ログファイル検証）

## 前提

S3 に出している証跡がないと始まらない。
今は Terraform で有効な証跡がないので、まず1本作る。
[証跡バケットの Object Lock](2026-09-26-CloudTrail証跡バケットはTerraformのミスで消えるのでObject_Lockをかける.md) と同じ証跡でまかなえる。

詳細は [CloudTrail を DuckDB で掘るか Athena で掘るか](../docs/Amazon%20Web%20Services/04_セキュリティ/検知と可視化/CloudTrailをDuckDBとAthenaで掘る比較.md)。
