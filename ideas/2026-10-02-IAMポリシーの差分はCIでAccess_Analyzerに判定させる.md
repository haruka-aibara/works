tags: aws, iam, access-analyzer, terraform, ci, security

# IAM ポリシーの差分は CI で Access Analyzer に判定させる

Terraform の PR で IAM ポリシーを変えると、レビューは結局「なんとなく読む」になる。
AI に書かせるならなおさら、人間の目で全部は追えない。

IAM Access Analyzer のカスタムポリシーチェックは、ポリシーを論理的に判定してくれる。

- `check-no-new-access`：変更前より権限が広がっていないか
- `check-access-not-granted`：`iam:PassRole` や `s3:DeleteBucket` など、決めた操作を許していないか
- `check-no-public-access`：リソースポリシーが外部に公開していないか

`terraform plan` の JSON からポリシーを抜いて、PR の CI で回す。
広がったときだけ人間が見る、という分担にできる。

## AI レビューとの違い

AI は「たぶん大丈夫」と言えてしまう。
Access Analyzer は自動推論で、条件キーやワイルドカードまで含めて広がったかを判定する。

## 気をつけること

- 1 回ごとに課金される。全ポリシーではなく差分だけにかける
- CI から AWS に繋ぐことになる。OIDC で、Access Analyzer の API だけ叩けるロールを使う
- plan から抜き出す部分は AWS の OSS ツールがあったはず（未確認）
