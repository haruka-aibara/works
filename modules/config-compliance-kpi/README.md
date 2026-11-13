# config-compliance-kpi

複数の AWS Config ルールの非準拠リソース数を合計し、CloudWatch ダッシュボードで推移を追うモジュール。

Config はルールごとの非準拠数をメトリクスとして出さないので、
Step Functions が定期的に `DescribeComplianceByConfigRule` を呼んで `PutMetricData` する。
コードを持ちたくないので Lambda は使わず、SDK 統合と JSONata だけで組んでいる。

## 制約

- ルールごとの数は `CappedCount` なので 100 で頭打ちになる。KPI の傾向を見る用途なら困らない想定。
