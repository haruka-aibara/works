tags: aws, iam, github-actions, oidc, terraform, security

# GitHub OIDC のロールは sub で絞り忘れると他人のリポジトリから入られる

GitHub Actions から OIDC で AssumeRole するロールの信頼ポリシーで、`token.actions.githubusercontent.com:sub` の条件を書き忘れると、
GitHub 上の**誰のリポジトリからでも**そのロールを引き受けられる。
`aud`（`sts.amazonaws.com`）だけでは、全 GitHub ユーザー共通なので絞れていない。

## 絞り方

- `repo:OWNER/REPO:ref:refs/heads/main` のように、リポジトリとブランチまで書く
- `StringLike` で `repo:OWNER/*` にすると、組織の全リポジトリ・全ブランチ・全 PR から入れる。apply 用のロールでは避ける
- apply 用と plan 用でロールを分け、apply 用は `main` と `environment:production` に限る

## 確認すること

- 既存のロールの信頼ポリシーを `sub` 条件で棚卸しする。IAM Access Analyzer の外部アクセス検出で拾えるかは未確認
- `pull_request` イベントの `sub` は `repo:OWNER/REPO:pull_request` になる。plan 用ロールで許すならこれだけにする

AWS 側で `sub` 条件のない信頼ポリシーを作れないようにする変更が入った、という話を聞いたことがあるが、いつからか・既存ロールにも効くかは未確認。
