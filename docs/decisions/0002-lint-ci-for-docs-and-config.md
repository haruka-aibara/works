# ADR-0002: YAML / ワークフロー / Markdown を lint CI で機械チェックする

## ステータス

採用 (2026-09-23)

## コンテキスト

このリポジトリの中身の大半は Terraform ではなく、学習メモ（md 約1000本・HTML 約200本）とワークフローの YAML。これまで CI が見ていたのは Terraform と Python だけで、文書と設定ファイルは誰もチェックしていなかった。

導入時に既存ファイルを走らせたら、実際に次のものが見つかった。

- Marp ガイドのコードブロックの閉じ位置がずれて、以降の本文がすべてコード扱いで表示されていた
- 見出しレベルの飛び、画像の alt 抜け
- 見出し・リスト前後の空行抜けが数千か所。レンダラによっては見出しやリストとして解釈されない

どれも書いた時点では気づけず、表示して初めて分かる類の崩れ。AI に記事を書かせる運用なので量が増える一方で、目視では追いつかない。

## 決定

`.github/workflows/` の `yaml-lint.yml`・`github-actions-lint.yml`・`markdown-lint.yml` で、PR と main への push ごとに次を走らせる。落ちたらマージしない。

| ツール | 対象 | 設定 |
|---|---|---|
| yamllint | `*.yml` / `*.yaml` | `.yamllint.yml` |
| actionlint | `.github/workflows/`（`run:` の shellcheck を含む） | なし |
| zizmor | `.github/workflows/` と配布元の `ci/workflows/` | `.github/zizmor.yml` |
| markdownlint（markdownlint-cli2） | `*.md` | `.markdownlint-cli2.jsonc` |

- **ツールは各形式のデファクトから選ぶ。** 根拠は「大手の文書リポジトリが実際に使っているか」と「リンター集約ツール（[Super-Linter](https://github.com/super-linter/super-linter)・[MegaLinter](https://github.com/oxsecurity/megalinter)）がその形式の標準として採用しているか」。2026-09 時点で確認した。
  - **markdownlint**: GitHub Docs のコンテンツリンターは markdownlint の上に独自ルールを足したもの（[コンテンツ リンターの使用](https://docs.github.com/ja/contributing/collaborating-on-github-docs/using-the-content-linter)、[github/docs の content-linter README](https://github.com/github/docs/blob/main/src/content-linter/README.md)「新しいルールを作る前に Markdownlint にないか確認する」）。MDN（[mdn/content の package.json](https://github.com/mdn/content/blob/main/package.json)）は markdownlint-cli2 を使っている。Super-Linter・MegaLinter とも Markdown の標準リンター。
  - **yamllint**: GitHub-hosted の Ubuntu ランナーイメージに最初から入っている（[actions/runner-images の Ubuntu 24.04 README](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md)）。ansible-lint は内部で yamllint を使っている。Super-Linter・MegaLinter とも YAML の標準リンター。
  - **actionlint**: Super-Linter・MegaLinter とも GitHub Actions の標準リンター。
  - **zizmor**: Super-Linter が actionlint と並べて GitHub Actions 用に採用している。CPython も pre-commit に actionlint と並べて入れている（[python/cpython の .pre-commit-config.yaml](https://github.com/python/cpython/blob/main/.pre-commit-config.yaml)）。actionlint が構文を見るのに対し、こちらはテンプレートインジェクション・過剰な `permissions`・action の未固定・認証情報の残留といったセキュリティ面を見るので、役割は重ならない。
- **Markdown は `--fix` で空行まわりを自動修正できるのも決め手。** 独自ルールを書かずに済む。
- **見るのは「構造の崩れ」だけ。書き方の好みは見ない。** 行長・表の列揃え・コードの言語指定・見出し末尾の句読点・同名見出しなどは無効にする。1000本超の既存メモを好みに合わせて書き換えるのは割に合わず、ノイズが多いと CI を無視するようになる。
- **自動修正で本文が変わるルールは切る。** 番号付きリストの番号チェック（`ol-prefix`）は、画像などで分断されたリストの番号を 1. に振り直して表示を変えてしまう。見出し末尾の「。」を消すルールも本文の変更になる。
- **action はコミットハッシュで固定する。** タグは付け替えられるので、第三者の action はハッシュ固定（`# vX.Y.Z` のコメント付き。Renovate が両方更新する）。自分の共通ワークフロー（`haruka-aibara/*`）だけは main を追う運用なのでブランチ参照を許す。配布元の `ci/` も同じ基準で直した（`permissions: contents: read` の明示、`persist-credentials: false`、`run:` 内の `${{ }}` を環境変数経由に）。main へのマージで Terraform が配布先の全リポジトリに反映する。
- **導入と同時に既存の違反はすべて直す。** 除外リストで既存ファイルを逃がすと、そのファイルを触るたびに落ちる。対象外にしたのは、書き方の見本そのもの（`docs/Markdown/cheatsheet.md`）と Marp のスライドだけ。
- **記事の書き方は article-writing スキルに反映する。** AI が書く段階でルールに沿わせ、CI は取りこぼしの検出に回す。

## 検討した代替案

- **Terraform で他リポジトリに配布する（`ci/`）。** 対象の文書はこのリポジトリにしかないので、配布の仕組みに乗せる必要がない。直接置く。
- **HTML のリンター。** Markdown・YAML・Actions と違って定番が無い（Super-Linter・MegaLinter は HTMLHint、Bootstrap は W3C の Nu Html Checker と、採用がばらけている）。デファクトと言えるものが無いのに無理に入れることはしない。導入を試したときに見つかった崩れ（表の `thead` / `th scope`、コード中の生の `&`、href 内の空白）は直してある。
- **リンク切れチェック（lychee など）。** 外部リンクの死活で CI が不安定になるので見送り。

## トレードオフ

- 記事を書くたびに空行などで CI が落ちうる。手元で `npx markdownlint-cli2 --fix "**/*.md"` を流せば大半は直る。
- 無効にしたルールの範囲の崩れ（表の見た目、リストの番号など）は引き続き目視頼み。
- ツールのバージョンは、action のコミットハッシュ・ワークフローの `env`（`*_VERSION`）・actionlint のイメージで固定し、Renovate が上げる。
  上げるとルールが増えて既存ファイルが落ちることがあるので、Renovate の PR の中で直す。
