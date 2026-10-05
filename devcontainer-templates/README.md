# devcontainer-templates

VS Code の devcontainer テンプレート。旧 `haruka-aibara/devcontainer-templates` リポジトリをこのモノレポに統合したもの。

## 使い方

1. VS Code でコマンドパレット（`Ctrl+Shift+P`）を開く
2. **Dev Containers: Clone Repository in Container Volume...** を選ぶ
3. テンプレート ID を入力する

```
ghcr.io/haruka-aibara/works/haruka-aibara-dev-env:latest
```

## 構成

```
devcontainer-templates/
  README.md                          # このファイル
  scripts/update-checksums.sh        # Dockerfile の CLAUDE_SHA256_* をバージョンに合わせて書き換える
  docs/adr/                          # 設計判断の記録
  docs/superpowers/                  # 初期設計時の plan / spec
  src/haruka-aibara-dev-env/
    devcontainer-template.json       # テンプレートのメタ情報（version は次に出す番号の下限）
    .devcontainer/
      Dockerfile                     # ベースイメージとツールのピン
      devcontainer.json              # 拡張機能・設定・features
      devcontainer-lock.json         # features の digest ピン
      post-create.sh                 # コンテナ作成後のセットアップ
      smoke-test.sh                  # 必須ツールの存在確認
```

`.gitignore` はルート直下の `/.devcontainer` だけを無視する。テンプレート配下の `.devcontainer/` は追跡対象なので、無指定の `.devcontainer` に戻さないこと。

## 含まれるツール

| 入れ方 | ツール |
|---|---|
| devcontainer Features | aws-cli, github-cli, kubectl / helm / minikube, node, python, docker-in-docker |
| Dockerfile | gcloud（Google 公式 apt リポジトリ）, tenv / uv（公式イメージから COPY）, Claude Code, jq / curl / wget / htop / tree / zip / tar |
| post-create.sh | flake8, pylint, pyre-check, pytest, ansible-core, ansible-lint（uv tool）, Terraform 最新安定版（tenv）, Mermaid の AWS アイコン設定 |

公式 Feature があるものは Feature に寄せ、無いものだけ Dockerfile にバージョンピン + SHA256 検証で残す方針。理由は [`docs/adr/0002-prefer-devcontainer-features.md`](docs/adr/0002-prefer-devcontainer-features.md)。

## ハッシュの自動更新

| 対象 | 更新するもの |
|---|---|
| `Dockerfile` の `BASE_IMAGE` digest | Renovate（`renovate.json` の customManagers）。`# renovate:` コメントの `tag=ubuntu-24.04` の digest を追う |
| `Dockerfile` の tenv / uv | Renovate（標準の dockerfile マネージャー）。公式イメージを `COPY --from=<image>:<tag>@<digest>` で取り込んでいる |
| `Dockerfile` の `CLAUDE_VERSION` | Renovate（公式プリセット `customManagers:dockerfileVersions`）。週 1 回・公開から 3 日経ったものだけ |
| `Dockerfile` の `CLAUDE_SHA256_*` | Renovate では計算できないので、`renovate/**` ブランチで `.github/workflows/devcontainer-checksums.yaml` が `scripts/update-checksums.sh` を実行して追いコミットする。GITHUB_TOKEN の push では PR の CI が承認待ちで止まるので、続けて必須チェック（Lint・Terraform CI）を `workflow_dispatch` で起動する |
| `devcontainer.json` / `devcontainer-lock.json` の features | Dependabot（`.github/dependabot.yml`）。Renovate は lock を更新できないので、Renovate の devcontainer マネージャーは無効 |

ホストの認証情報はマウントしない。コンテナ内で `aws login` / `gcloud auth login` / `gh auth login` する（[`docs/adr/0004-auth-no-long-lived-secrets.md`](docs/adr/0004-auth-no-long-lived-secrets.md)）。

## リリースフロー

`.github/workflows/devcontainer-release.yaml` が担当する。`workflow-dist/` から配布される CI とは別で、Terraform 管理外なので直接編集してよい。

- `devcontainer-templates/src/**` または当該ワークフローへの push（main）で自動実行
- ghcr に publish 済みの最新バージョンを見て次の番号を決め、ジョブの中だけで `devcontainer-template.json` を書き換えて publish する
- Actions タブから `workflow_dispatch` で手動実行もできる（`skip_version_bump: true` なら bump せず、publish 済みの最新バージョンで再 publish）

CI は main に bump コミットを push しない。
main はブランチ保護（必須チェック + `enforce_admins`）で CI からの直接 push を受け付けず、以前の push 方式は毎回ここで失敗していた。

### バージョン bump ルール

| main のコミットメッセージ（マージコミットなら PR タイトルも含む） | 変化 |
|---|---|
| `feat: ...` | minor bump（1.4.x → 1.5.0）|
| `fix: ...` / その他 | patch bump（1.4.12 → 1.4.13）|
| `BREAKING ...` / `feat!: ...` | major bump（1.4.x → 2.0.0）|

- ファイルの `version` は「次に出す番号の下限」。publish 済みの最新より大きくすれば、bump ルールを無視してその番号で出る（例: 2.0.0 に上げる）
- そうでなければファイルの番号は使われないので、publish 済みの番号と食い違っていてもよい

### publish 先

`devcontainers/action@v1` は `ghcr.io/<owner>/<repo>/<template id>` に publish する。リポジトリが変われば publish 先も変わる。

| いつ | publish 先 |
|---|---|
| 現在（`haruka-aibara/works`） | `ghcr.io/haruka-aibara/works/haruka-aibara-dev-env` |
| 統合前（`haruka-aibara/devcontainer-templates`） | `ghcr.io/haruka-aibara/devcontainer-templates/haruka-aibara-dev-env`（〜1.3.1、更新停止）|
| org 移動前（個人アカウント） | `ghcr.io/haruka-aibara-dev/devcontainer-templates/haruka-aibara-dev-env`（〜1.3.0、更新停止）|

package はリポジトリを移しても付いてこないので、publish し直しが要る。統合後の初回 publish でやる手作業は [`docs/runbooks/devcontainer-template-monorepo-migration.md`](../docs/runbooks/devcontainer-template-monorepo-migration.md) を見ること。
