# エージェント作業ガイド

管理対象を全部集約するリポジトリ。Terraform コード・CI 配布・実装コード・学習メモが同居する。

**聞かれたことに、必要な長さで答える。** 前置きや質問の言い換えは足さない。短い質問には短く返す。

**必要なものだけ読む。以下は常時読まない。**

| 触るもの | 読む |
|---|---|
| ルートの `*.tf` / `modules/` / `workflow-dist/` | `README.md` |
| `docs/` 配下 | `docs/reference/README.md` |
| `devcontainer-templates/` | `devcontainer-templates/README.md` |
| 運用手順・過去の経緯を調べる | `docs/runbooks/README.md` |

**README に運用メモを載せない。** 運用手順・ランブックの索引は `docs/runbooks/README.md` に置き、README からは参照しない。

**`docs/Ideas/` は 1500 文字以内の入口だけにする。** 結論と要点だけ書き、詳細は `docs/` の該当トピックのディレクトリに書いてリンクする。

**PRを作るときは `.github/PULL_REQUEST_TEMPLATE.md` に従う。** 概要・変更内容・関連Issue の見出しをそのまま使い、本文を埋める。

**日本語の markdown は、意味の切れ目で改行し、話が変わったら空行を空ける。** 長い段落を1行に詰めない。

**README には、コードだけだと推測になってしまう情報だけ書く。** 使い方・一覧・コードのコメントやクラウドの仕様でわかることは書かない。
