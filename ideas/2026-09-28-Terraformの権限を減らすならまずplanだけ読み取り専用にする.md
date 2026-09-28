tags: terraform, hcp-terraform, aws, iam, oidc, ai, security

# Terraform の権限を減らすなら、まず plan だけ読み取り専用にする

apply に要る権限を洗い出して絞るのは重い。
先に plan だけ読み取り専用にするほうが、簡単で効き目も大きい。

## なぜ plan か

`works` の AWS 認証は `TFC_AWS_RUN_ROLE_ARN` の1本だけ。
PR の speculative plan も、apply と同じ書き込み権限で動いている。

plan の中でも任意のコードは動く（`data "external"` や provider のコード）。
つまり、マージしなくても PR を出すだけで AWS を操作できる。
「AI は PR まで」の分担も、いまは成り立っていない。

apply は main へのマージでしか走らないので、書き込みの経路をマージだけに寄せられる。

## やること

- `TFC_AWS_PLAN_ROLE_ARN` と `TFC_AWS_APPLY_ROLE_ARN` を分ける
- plan 用は読み取り専用にし、`sub` を `...:workspace:works:run_phase:plan` に絞る。`ReadOnlyAccess` は SSM パラメータも読めるので、そのままは付けない
- apply 用は `run_phase:apply` だけに信頼させる

## これでは残るもの

ワークスペースの環境変数（GitHub App の秘密鍵、`TFE_TOKEN` など）は plan からも読める。
ロールを分けても塞がらないので、別に考える。

## 未確認

- 読み取り専用で plan が通るか（`aws_lambda_invocation` のような、plan で書き込むものがないか）
- plan 中に外部コマンドから Web Identity トークンを読めるか
