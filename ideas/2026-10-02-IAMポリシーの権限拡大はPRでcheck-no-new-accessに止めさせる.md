tags: aws, iam, access-analyzer, terraform, ci, security

# IAM ポリシーの権限拡大は PR で check-no-new-access に止めさせる

IAM ポリシーの差分は、人間の目だと荒くしか拾えない。
IAM Access Analyzer のカスタムポリシーチェックを PR の CI で叩けば、変更前と比べて権限が広がったかを機械が判定してくれる。

## 使う API

- `check-no-new-access`：変更前のポリシーを参照にして、新しいポリシーが新しいアクセスを足していないか
- `check-access-not-granted`：「`iam:PassRole` と `kms:Decrypt` は絶対に許さない」のような禁止リスト
- `check-no-public-access`：リソースポリシーが外部公開になっていないか

結果は PASS / FAIL なので、FAIL のときだけ PR を止めて人間が見る。

## 置き場所

`terraform plan -json` からポリシーを抜き出して投げる。
awslabs に Terraform の plan を読んでチェックするツールがあるはず（未確認：名前と保守状況）。
このリポジトリなら `workflow-dist/` で配る CI に足せる。

## 気になるところ（未確認）

- 呼び出しごとに課金。PR ごとに数本なら誤差のはず
- CI から呼ぶには AWS の認証が要る。OIDC で、Access Analyzer の API だけ呼べるロールにする
- 判定は推論ベースなので、`Condition` が絡むと保守的に FAIL になることがありそう
