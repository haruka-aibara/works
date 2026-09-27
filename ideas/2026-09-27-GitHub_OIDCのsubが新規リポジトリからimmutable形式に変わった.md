tags: github, github-actions, aws, iam, oidc, security

# GitHub OIDC の sub が新規リポジトリから immutable 形式に変わった

2026-07-15 以降に作ったリポジトリ（と、リネーム・移管したリポジトリ）では、OIDC トークンの `sub` が
`repo:OWNER@OWNER-ID/REPO@REPO-ID:ref:refs/heads/BRANCH` という形式になった。
既存のリポジトリは、opt-in しない限り旧形式のまま。

## 効くところ

- AWS 側の信頼ポリシーに `repo:org/repo:*` と書いていると、新しいリポジトリからは AssumeRole が通らなくなる。壊れ方としては安全側
- 旧形式は名前だけで照合するので、org やリポジトリの名前が再利用されると、別人が同じ `sub` を出せてしまう。immutable 形式は ID で縛るので、これが塞がる

## 判断

- 新規リポジトリの信頼ポリシーは、最初から ID 入りの形式で書く
- 既存のものも、名前の再利用が気になる org なら opt-in して書き換える
- `sub` のない信頼ポリシーはすでに IAM 側で作れない。残る論点はワイルドカードの広さと、StringEquals と StringLike の使い分け

## 未確認

opt-in の方法（リポジトリ単位か org 単位か、API の OIDC customization か）。
