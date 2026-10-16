tags: terraform, hcp-terraform, ci

# PR の plan と merge 後の plan を比べる仕組みは、きれいに作れない

VCS 連携の HCP Terraform で、「PR で見た speculative plan」と「merge 後の plan」が同じかを自動で比べようとして、ボツにした。

HCP Terraform には run 同士を比べる機能がない。
自分で作ると、2つの run を探し、plan の完了を待ち、plan JSON を取って diff する仕組みになる。
試すと、どこにも素直に作れる部品がなかった。

- plan JSON（`json-output`）を読むにはワークスペースの admin 権限が要る。read 権限で読める redacted 版は API ドキュメントに載っていない
- Free プランでは team を作れないので、結局 owners team のトークンを GitHub に置くことになる
- plan JSON の `relevant_attributes` は並び順が毎回変わる（Terraform 側の不具合）ので、ただの diff だと誤検知する

## 得られるものが小さい

PR を main に追いついた状態でしか merge しないなら、コードは PR と同じ。
plan に差が出るのは、手作業の変更などコードの外が変わったときだけになる。

「想定外の変更が apply されるのが怖い」が本音なら、`auto_apply` を切って Confirm 前に plan を見れば足りる。
比較の仕組みが追加で見つけるものは、ほとんどない。

調べたことの詳細は [PR の plan と merge 後の plan の比較](../docs/Terraform/23_HCP/23-09_PRとmerge後のplanの比較.md)。
