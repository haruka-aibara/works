# works

作るもの・管理するものを、別リポジトリを切らずに全部ここへ集める個人のモノレポ。

## 方針

- **GitHub もクラウドも Terraform で持つ。** 手で作らず、このリポジトリから apply する
- **アプリのコードは、それを動かすインフラと同じモジュールに置く。**
- **学んだことは記事にして公開する。** `docs/` に書き、[GitHub Pages](https://haruka-aibara.github.io/works/) で読めるようにする。書き方は [`docs/reference/README.md`](docs/reference/README.md)
- **開発環境はファイルに書いておく。** このリポジトリで使うツールは `mise.toml`、どのリポジトリでも使うツールと Claude Code の設定は `devenv/` に置く
- **ハンズオンで試しただけのものも、リポジトリを切らずに `hands-on/` に置く。** 1つにつき1ディレクトリで、apply もデプロイもしない
- **使わなくなったものは消さずに止める。** モジュールは残し、`main.tf` の呼び出しをコメントアウトしておく

## 使い方

WSL2 の Ubuntu で、最初に 1 回だけ実行する。

```bash
# Claude Code を囲いの中で動かすための部品（bubblewrap・socat）と、hook が使う jq を入れる
# https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2
# https://code.claude.com/docs/en/hooks
sudo apt install -y jq bubblewrap socat

# mise（ツールをまとめて入れてくれる道具）を入れる
# Ubuntu の標準には無いので、配布元を登録してから入れる
# https://mise.jdx.dev/installing-mise.html#apt
sudo apt install -y extrepo && sudo extrepo enable mise
sudo apt update && sudo apt install -y mise

# ターミナルを開くたびに mise が働くようにする
# これがあると、terraform と打つだけで、いるディレクトリの mise.toml の版が使われる（無ければその場で入る）
# これが無いと、毎回 mise exec -- terraform のように mise を通して打つことになる
# https://mise.jdx.dev/getting-started.html#activate-mise
echo 'eval "$(mise activate bash)"' >> ~/.bashrc && exec bash

# このリポジトリを手元に持ってくる
# https://docs.github.com/ja/repositories/creating-and-managing-repositories/cloning-a-repository
git clone https://github.com/haruka-aibara/works ~/src/works

# 「どこでも使うツールの一覧」として、このリポジトリのファイルを mise に読ませる
# https://mise.jdx.dev/configuration.html#global-config
mkdir -p ~/.config/mise
ln -s ~/src/works/devenv/mise.toml ~/.config/mise/config.toml

# Claude Code の「やっていいこと・だめなこと」の設定を置く
# このリポジトリの中では .claude/settings.json が効くので、これはほかのリポジトリでも同じにするため
# 「許可していないサイトは確認なしで拒否」「sandbox が使えなければ起動しない」は、この置き場所でしか効かない
# https://code.claude.com/docs/en/settings
mkdir -p ~/.claude
cp ~/src/works/devenv/claude/settings.json ~/.claude/settings.json
```

あとは、このリポジトリに入ってふだんどおりコマンドを打つだけ。

```bash
cd ~/src/works
# terraform が入っていなくても、ここで自動で入ってから動く
# https://mise.jdx.dev/configuration/settings.html#not_found_auto_install
terraform plan
```

- ツールと版は、このリポジトリで使うものを `mise.toml`、どこでも使うもの（aws-cli・gh など）を `devenv/mise.toml` に書いてある。更新は Renovate の PR をマージするだけ
- Claude Code は sandbox の中で動く。ツールのインストール、`~/.aws` などの認証情報の読み取り、許可していないサイトとの通信はできない
- apt の自動更新・gcloud・VS Code の設定など、細かい手順と理由は [開発環境の手順書](docs/runbooks/wsl-mise-claude-sandbox.md)

## main へのマージで起きること

- **HCP Terraform が apply する。** ワークスペース `works` は `auto_apply = true` なので、plan を確認する段階がなくそのまま反映される。ローカルでやるのは検証まで
