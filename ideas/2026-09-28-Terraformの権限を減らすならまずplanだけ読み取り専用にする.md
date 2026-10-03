tags: terraform, hcp-terraform, aws, iam, oidc, ai, security

# Terraform の権限を減らすなら、まず plan だけ読み取り専用にする

apply に要る権限を洗い出して絞るのは重い。
先に plan だけ読み取り専用にするほうが、簡単で効き目も大きい。

## なぜ plan か

HCP Terraform の動的認証を `TFC_AWS_RUN_ROLE_ARN` の 1 本で組むと、
PR の speculative plan も apply と同じ書き込み権限で動く。

plan の中でも任意のコードは動く（`data "external"` や provider のコード）。
つまり、マージしなくても PR を出すだけで AWS を操作できる。
「AI は PR まで、マージは人間」という分担も、この状態では成り立たない。

apply がマージでしか走らないなら、書き込みをマージだけに寄せられる。

## やること

- `TFC_AWS_PLAN_ROLE_ARN` と `TFC_AWS_APPLY_ROLE_ARN` を分ける
- plan 用は読み取り専用にし、`sub` を `...:workspace:<名前>:run_phase:plan` に絞る。`ReadOnlyAccess` は SSM パラメータも読めるので、そのままは付けない
- apply 用は `run_phase:apply` だけに信頼させる

## これでは残るもの

ワークスペースの環境変数に置いた秘密は plan からも読める。別に考える。

## 未確認

読み取り専用で plan が通るか（`aws_lambda_invocation` など、plan で書き込むものがないか）。
