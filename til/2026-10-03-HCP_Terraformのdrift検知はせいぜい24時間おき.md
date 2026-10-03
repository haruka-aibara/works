tags: terraform, hcp-terraform

# HCP Terraform の drift 検知は、せいぜい 24 時間おき

HCP Terraform の drift 検知（health assessment）は、約 24 時間ごとに refresh-only plan を走らせる仕組み。
間隔を変える設定はなく、プランを上げても短くならない。
上位プランで増えるのは、組織全体での一覧や一括強制（`assessments_enforced`）で、頻度ではない。

有効化と Slack 通知は、どちらも Terraform で管理できる。

- `tfe_workspace` の `assessments_enabled = true`
- `tfe_notification_configuration` の triggers に `assessment:drifted` などを入れる

通知は状態が変わったときだけ届く。
diff の中身は載らず、Health 画面へのリンクだけになる。

## 即時の検知は workspace とリポジトリだけではできない

drift は plan を走らせて初めてわかる。
HCP Terraform には「外で誰かが変えた」ことを知るきっかけがない。

- 間隔を詰めたいなら、GitHub Actions の schedule で `terraform plan -refresh-only -detailed-exitcode` を回す。
  ただし schedule は最短 5 分間隔で、実際には遅れることも多い。
  Free プランは同時実行が 1 なので、本番の apply が待たされる
- 本当に即時にしたいなら、クラウド側のイベント（AWS なら CloudTrail → EventBridge）を起点にするしかない
