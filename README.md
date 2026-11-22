# works

作るもの・管理するものを、別リポジトリを切らずに全部ここへ集める個人のモノレポ。

## 方針

- **GitHub もクラウドも Terraform で持つ。** 手で作らず、このリポジトリから apply する
- **アプリのコードは、それを動かすインフラと同じモジュールに置く。**
- **学んだことは記事にして公開する。** `docs/` に書き、[GitHub Pages](https://haruka-aibara.github.io/works/) で読めるようにする。書き方は [`docs/reference/README.md`](docs/reference/README.md)
- **開発環境はファイルに書いておく。** ツールは `mise.toml`、Claude Code の設定は `.claude/settings.json`、VS Code の設定などは `devenv/` に置く
- **ハンズオンで試しただけのものも、リポジトリを切らずに `hands-on/` に置く。** 1つにつき1ディレクトリで、apply もデプロイもしない
- **使わなくなったものは消さずに止める。** モジュールは残し、`main.tf` の呼び出しをコメントアウトしておく

## 使い方

WSL2 の Ubuntu で、最初に 1 回だけ実行する。

```bash
# Claude Code を囲いの中で動かすための部品（bubblewrap・socat）を入れる
# https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2
sudo apt update && sudo apt install -y bubblewrap socat

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
```

あとは、このリポジトリに入ってふだんどおりコマンドを打つだけ。

```bash
cd ~/src/works
# terraform が入っていなくても、ここで自動で入ってから動く
# https://mise.jdx.dev/configuration/settings.html#not_found_auto_install
terraform plan
```

- ツールと版は `mise.toml` に書いてある。更新は Renovate の PR をマージするだけ
- Claude Code は、このリポジトリの `.claude/settings.json` の設定で sandbox の中で動く（コピーなどの準備は要らない）。ツールのインストールと、`~/.aws` などの認証情報の読み取りはできない。許可していないサイトと通信するときは確認が出る
- apt の自動更新・gcloud・VS Code の設定など、細かい手順と理由は [開発環境の手順書](docs/runbooks/wsl-mise-claude-sandbox.md)

### 入るもの

- mise で入る（版は `mise.toml` で固定）
  - インフラ：terraform 1.17.1、tflint 0.66.0
  - クラウド・GitHub：aws-cli 2.41.2、gcloud 594.0.0、gh 2.105.0
  - Kubernetes：kubectl 1.37.2、helm 4.3.2、minikube 1.39.0
  - 言語：node 26.13.1、python 3.15.2、uv 0.13.9
  - Python 製ツール：flake8 7.5.0、pylint 4.1.4、pyre-check 0.10.0、pytest 9.2.0、ansible-core 2.22.0、ansible-lint 26.11.0
  - その他：jq 1.8.2、Claude Code 2.1.323
- mise では入らない
  - bubblewrap・socat：apt で入れる（Claude Code の sandbox の部品。mise に無い）
  - mise 本体：apt で入れる
  - docker：Docker Desktop の WSL 連携で使う（デーモンが要るので mise では入らない）

## main へのマージで起きること

- **HCP Terraform が apply する。** ワークスペース `works` は `auto_apply = true` なので、plan を確認する段階がなくそのまま反映される。ローカルでやるのは検証まで
