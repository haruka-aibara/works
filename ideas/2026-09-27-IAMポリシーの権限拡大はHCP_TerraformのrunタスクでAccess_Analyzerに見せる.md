tags: aws, iam, access-analyzer, terraform, hcp-terraform, ai, security

# IAM ポリシーの権限拡大は HCP Terraform の run タスクで Access Analyzer に見せる

AI に IAM ポリシーを書かせると、動かすために広めに書かれやすい。
レビューで人が Action を1個ずつ読むより、機械に「前より権限が増えたか」「危ない Action を渡していないか」を判定させたい。

- `check-no-new-access`: 変更前のポリシーと比べて、権限が増えていたら落とす
- `check-access-not-granted`: `iam:PassRole` や `s3:DeleteBucket` など、指定した Action を渡していたら落とす

## どこで回すか

GitHub Actions で回すと、GitHub 側に AWS の認証情報を新しく持たせることになる。
このリポジトリの AWS 認証は HCP Terraform にしかないので、run タスク（Free でも使える）で回すほうが増えるものが少ない。
`aws-ia/terraform-aws-runtask-iam-access-analyzer` というモジュールがある。

## ただし

run タスクの受け口として、Lambda などを自分のアカウントに置くことになる。
いまの IAM ポリシーの数なら、その保守の手間のほうが重いかもしれない。
本業で、IAM を AI に書かせるチームに持っていく案として温める。
