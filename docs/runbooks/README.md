# ランブック

運用メモの索引。README には出さない。

- [GitHub 認証のしくみ](../reference/github-authentication.md) — workspace の変数や GitHub App が何者かを調べるとき
- [GitHub Organization 移行 + GitHub App 認証 移行手順書](github-org-migration-and-app-auth.md) — この構成に至った経緯
- [devcontainer テンプレートのモノレポ統合](devcontainer-template-monorepo-migration.md) — 旧リポジトリを畳むとき、ghcr の package を作り直すとき
- [TFE_TOKEN 自動ローテーション](tfe-token-rotation.md) — 初回のブートストラップ、漏洩時の手順、文鎮化からの復旧
  - 設計の判断は [ADR-0001](../decisions/0001-tfe-team-token-rotation.md)
- [HCP Vault の HCP Terraform secrets engine](hcp-vault-tfe-secrets.md) — 立ち上げ（PR 2 本）、rotate-root の確かめ方、片付け
- [bedrock-slack-ai-chatbot の state 統合](bedrock-slack-ai-chatbot-state-merge.md) — 旧ワークスペースの state を works に寄せたときの記録
- [Claude の定期調整](claude-tuning.md) — 新モデルが出たとき、指示ファイル・スキル・Slack ボットのモデルを見直すとき
- lint CI（yamllint / actionlint / zizmor / markdownlint）— なぜ入れたか、どこまで見るかは [ADR-0002](../decisions/0002-lint-ci-for-docs-and-config.md)
- [Renovate の当番制と Slack 通知](../GitHub/41_Renovate/当番制とSlack通知.md) — 当番を足す・減らすとき、Slack のチャンネルに Renovate の PR を流すとき
