tags: aws, inspector, sbom, duckdb, vulnerability, nvd, incident-response, security

# 重大な脆弱性の「どこで使ってる？」を Inspector を待たずに引く

Inspector の finding は、脆弱性が Inspector の DB に載って初めて出る。
今は NVD の分析が積み残され、報告数も増えて、公表から DB に載るまでの空白が長くなりがち。
Inspector だけ見ていると、この空白に気づけない。

そこで Inspector の SBOM エクスポートを貯めておき、DuckDB で自分で引く。

## 仕組み

- EventBridge Scheduler で SBOM エクスポート（CycloneDX）を定期実行し、S3 に日付ごとに貯める
- 緊急時は DuckDB の `httpfs` で S3 の JSON を読み、`components` を `unnest` して purl で引く

CVE がなくても、アドバイザリのパッケージ名とバージョン範囲で当たりを付けられる。

## 出なかったを影響なしと読まない

スキャン対象外のリソースや、手で入れたバイナリは載らない。
カバレッジも出しておき、引けない範囲を答えに添える。

## Athena に移るとき

量が増えるか、複数人で引くようになったら。考え方は [CloudTrail を DuckDB で掘る](2026-09-29-CloudTrailはDuckDBで手元に落として掘る.md) と同じ。

エクスポートが無料か、JSON の形、入れ子をそのまま引けるかは未確認。
