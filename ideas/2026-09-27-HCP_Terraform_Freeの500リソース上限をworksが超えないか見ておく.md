tags: terraform, hcp-terraform, cost, operations

# HCP Terraform Free の 500 リソース上限を works が超えないか見ておく

旧 Free プランは 2026-03-31 で終わり、今の Free は管理リソース 500 個まで。
`works` は GitHub のリポジトリ・ブランチ保護・配布する workflow ファイル・AWS のリソースを全部1つのワークスペースで持っている。
リポジトリを1つ足すだけで、ファイル配布の分もあって何個も増える。

## やること

- `terraform state list | wc -l` で、いまの個数を見る
- 増え方が速いのは `github_repository_file` の配布。配布先 × ファイル数で効く
- 超えそうになったら、課金される前に、ワークスペースを分けるか、配布のやり方を変えるかを決める

`main.tf` の呼び出しをコメントアウトして止めたモジュールは、apply でリソースごと消えるので数に入らない。
数に入るのは、動いているものだけ。

## 未確認

data source や `null_resource` も数えるのか。数え方の定義を確認する。
