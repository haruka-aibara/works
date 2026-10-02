tags: aws, security-hub, terraform, ai, security, operations

# Security Hub CSPM の検出結果を AI に渡して Terraform の修正 PR を書かせる

FSBP の検出結果は直し方もたいてい Terraform の数行。
手が回らないのは判断ではなく作業量の問題。

AI に AWS は触らせず、検出結果を渡して修正 PR だけ書かせる。
マージと apply は人間、という線はそのまま守れる。

## 流れ

1. 人間か CI が `aws securityhub get-findings` で JSON を落とす
2. AI がリソース ARN からリポジトリ内の Terraform を探し、修正 PR を出す
3. Terraform 管理外のリソースだった場合は PR にせず、「管理外」として一覧に残す。[手作業の変更](2026-10-02-コンソール手作業の変更をCloudTrailから月1で洗い出す.md) の発見になる

## 向く検出・向かない検出

- 向く：暗号化・ログ・削除保護の有効化など、設定 1 個で閉じるもの
- 向かない：セキュリティグループの開け閉め、IAM の権限削減。業務影響を AI は判断できない

[FSBP の優先順位](../docs/Amazon%20Web%20Services/04_セキュリティ/検知と可視化/SecurityHub_FSBP優先順位の付け方.md) の上から「向く」ものだけ流す。

## 気になるところ

- JSON にはアカウント ID やリソース名が入る。AI に渡してよいか先に決める
- 抑制済みは渡さない
