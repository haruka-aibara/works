# devcontainer テンプレートのモノレポ統合

`haruka-aibara/devcontainer-templates` を廃止し、テンプレートの定義とリリースをこのリポジトリに寄せるための手順。

## 何が変わるか

- テンプレートの置き場所: `devcontainer-templates/src/haruka-aibara-dev-env/`（旧リポジトリの全コミット履歴 72 件ごと取り込み済み。`bedrock-slack-ai-chatbot` を統合したとき（`27da634`）と同じく `git filter-repo --to-subdirectory-filter` でパスを書き換えてから unrelated histories マージしている）
- publish するワークフロー: `.github/workflows/devcontainer-release.yaml`
- publish 先: `ghcr.io/haruka-aibara/devcontainer-templates/haruka-aibara-dev-env` → **`ghcr.io/haruka-aibara/works/haruka-aibara-dev-env`**

`devcontainers/action@v1` の publish 先は `ghcr.io/<owner>/<repo>/<template id>` 固定で、リポジトリ名がそのまま入る。ghcr の package はリポジトリを消しても別リポジトリに引き継がれないので、**新しい名前空間へ publish し直すまで旧 package を消さない**。

## 手順

### 1. 統合 PR をマージする

`devcontainer-templates/` 一式とリリースワークフローが main に入る。マージした時点で `devcontainer-templates/src/**` が変わっているので、リリースワークフローが自動で走る。

`.gitignore` の `.devcontainer` を `/.devcontainer`（ルート直下のみ）に直してある。無指定に戻すとテンプレート配下の `.devcontainer/` が丸ごと追跡対象から外れるので注意。

### 2. 初回 publish の結果を確認する

Actions の **devcontainers/action** ワークフローが成功すると、ジョブのログに publish されたタグが出る。

まず匿名 pull できるか確認する。private のままだと `Dev Containers: Clone Repository in Container Volume...` から参照できない。

```bash
TOKEN=$(curl -s "https://ghcr.io/token?scope=repository:haruka-aibara/works/haruka-aibara-dev-env:pull&service=ghcr.io" | jq -r .token)
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://ghcr.io/v2/haruka-aibara/works/haruka-aibara-dev-env/tags/list"
```

タグ一覧が返れば public。**token エンドポイントは private でも package が無くても token を返すので、token が返ったことだけを見ても判定にならない。** 実際に tags/list まで叩くこと。

2026-09-21 の初回 publish（1.4.0）ではこの時点で既に public になっており、下の手作業は要らなかった。403 が返るときだけやる。

1. Organization settings → Packages → Package creation で Public を許可しておく
2. org の Packages → `works/haruka-aibara-dev-env` → Package settings
   - Danger Zone → Change visibility → **Public**
   - Manage Actions access に `works` が入っているか確認（無ければ追加）

### 3. 実際にテンプレートから開いてみる

VS Code の **Dev Containers: Clone Repository in Container Volume...** で
`ghcr.io/haruka-aibara/works/haruka-aibara-dev-env:latest` を指定し、コンテナが立ち上がるところまで確認する。コンテナ内で smoke test を流すと必須ツールの有無を一括で見られる。

```bash
bash .devcontainer/smoke-test.sh
```

**ここまで通ってから次に進む。** 旧リポジトリはロールバック先なので、それまでは触らない。

### 4. 旧リポジトリを畳む

1. 旧 package（`devcontainer-templates/haruka-aibara-dev-env`）を deprecated 扱いにするか削除する
2. Terraform から管理を外す
   - `main.tf` の `module "devcontainer-templates"` を削除
   - `modules/repository` の `github_repository` には `prevent_destroy = true` が付いている。**リポジトリごと消す**なら `modules/repository/main.tf` の lifecycle を一時的に外して apply する（`bedrock-slack-ai-chatbot` を消したときと同じやり方）。**リポジトリは残して管理だけ外す**なら `removed { from = module.devcontainer-templates, lifecycle { destroy = false } }` を足す（`removed` ブロックは apply 後に消す一時的なもの）
   - `works` ワークスペースは `auto_apply = true`。main にマージした時点で apply が走るので、plan は PR の speculative run で確認する
3. GitHub 上でリポジトリを archive または delete する

旧リポジトリの履歴は #56 で取り込んだが、shallow clone から取り込んだため 72 コミット（2025-05-04 以降）
しか入っていなかった。#86 で main の全 118 コミットを取り込み直したので、旧リポジトリを消しても
履歴は失われない（#56 分と重複して 2 系統入っている）。

2026-09-25 に旧リポジトリを Terraform で destroy した（`prevent_destroy` を 1 apply だけ外すやり方）。

ただし**既定の `git log` / `git blame` は取り込んだコミットではなく #47 を指す**。#47 が先に
同じ内容を main 本線へ入れてしまい、マージの第1親（main 側）と内容が同じになるため、git の
history simplification が第2親（取り込んだ履歴）に降りないため。元のコミットを見るとき:

```bash
git log --full-history -- devcontainer-templates/src/haruka-aibara-dev-env/.devcontainer/Dockerfile
```

blame まで元の作者・日付にするには main の履歴を書き換える（force push）しかなく、
コストに見合わないと判断して現状維持にした。

## ロールバック

新しい名前空間で問題が出たら、旧リポジトリの Actions から `workflow_dispatch`（`skip_version_bump: true`）で旧名前空間に publish し直せる。旧リポジトリと旧 package を残しているあいだは、テンプレート ID を戻すだけで済む。

## 補足: bump コミットと HCP Terraform

以前のリリースワークフローは、version を bump したコミットを `[skip ci]` 付きで main に直接 push していた。
main にブランチ保護（必須チェック + `enforce_admins`）を入れてからはこの push が毎回弾かれ、publish まで進まなくなった。

今は version を PR の中で手で上げ、ワークフローは publish だけをする。
