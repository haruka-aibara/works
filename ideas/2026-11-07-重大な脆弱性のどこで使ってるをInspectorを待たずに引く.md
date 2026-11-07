tags: aws, inspector, sbom, duckdb, vulnerability, incident-response, security

# 重大な脆弱性の「どこで使ってる？」を Inspector を待たずに引く

Inspector の finding は脆弱性 DB への反映を待つ（[til](../til/2026-11-07-Inspectorの検出は脆弱性DBへの反映を待つ.md)）。
その間も自分で引けるように、SBOM エクスポートを貯めて DuckDB で引く。

## 仕組み

- EventBridge Scheduler で SBOM エクスポート（CycloneDX）を定期実行し、S3 に日付ごとに貯める
- 緊急時は DuckDB の `httpfs` で S3 の JSON を読み、`components` を `unnest` して purl で引く
- 常設のインフラが要らない。めったに使わない基盤なので効く

CVE がなくても、アドバイザリのパッケージ名とバージョン範囲で当たりを付けられる。
該当なしなら、その場で調査を閉じられる。

## 出なかったを影響なしと読まない

スキャン対象外のリソースや、手で入れたバイナリは載らない。
カバレッジも出しておき、引けない範囲を答えに添える。

## Athena に移るとき

量が増えるか、複数人で引くようになったら移す。考え方は [CloudTrail を DuckDB で掘る](2026-09-29-CloudTrailはDuckDBで手元に落として掘る.md) と同じ。

エクスポートの JSON の形と、入れ子をそのまま引けるかは未確認。
