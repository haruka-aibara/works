# works

作るもの・管理するものを、別リポジトリを切らずに全部ここへ集める個人のモノレポ。

## 方針

- **GitHub もクラウドも Terraform で持つ。** 手で作らず、このリポジトリから apply する
- **アプリのコードは、それを動かすインフラと同じモジュールに置く。**
- **学んだことは記事にして公開する。** `docs/` に書き、[GitHub Pages](https://haruka-aibara.github.io/works/) で読めるようにする。書き方は [`docs/reference/README.md`](docs/reference/README.md)
- **開発環境はファイルに書いておく。** このリポジトリで使うツールは `mise.toml`、どのリポジトリでも使うツールと Claude Code の設定は `devenv/` に置く
- **ハンズオンで試しただけのものも、リポジトリを切らずに `hands-on/` に置く。** 1つにつき1ディレクトリで、apply もデプロイもしない
- **使わなくなったものは消さずに止める。** モジュールは残し、`main.tf` の呼び出しをコメントアウトしておく

## main へのマージで起きること

- **HCP Terraform が apply する。** ワークスペース `works` は `auto_apply = true` なので、plan を確認する段階がなくそのまま反映される。ローカルでやるのは検証まで
