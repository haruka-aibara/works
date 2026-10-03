tags: iam, access-analyzer, terraform, least-privilege

# Access Analyzer の未使用権限から Terraform の削減 PR を自動で作る

最小権限は、探す・直す・確かめるが全部人の作業なので後回しになり続ける。
探すと直すを機械にやらせ、人は「マージするか」だけ判断する。

## 組み合わせるもの

- **IAM Access Analyzer の unused access**：未使用のロール・キー・権限を finding にする。
  未使用権限の finding は、`GenerateFindingRecommendation` で削ったあとのポリシー案を出せる
- **EventBridge**：finding の作成を拾って bot を起動する
- **bot（Lambda / CI）**：ポリシー案を取り、そのロールを定義している Terraform を書き換えて PR を作る

## 流れ

1. finding が出る → EventBridge から bot を起動
2. bot がポリシー案を取得し、ロールの ARN からコード内の定義を探して書き換え、PR を作る。本文に finding の ID と最終使用日を書く
3. 人がレビューしてマージ。apply 後に finding が解決済みになる

## 気をつけること

- 「未使用」は分析期間内の話。四半期に 1 回のバッチなどのロールは除外リストで外す
- 書き換えが難しければ、最初は PR 本文に差分案を貼るだけでよい
- 定義がコードに見つからないロールは、それ自体が IaC の外で作られたロールの検出になる

ポリシー案がイベントに含まれるかと、対応する finding の種類は未確認。
