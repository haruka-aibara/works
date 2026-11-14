# devcontainer をビルド済みイメージで配る

入口は [`ideas/2026-11-08-devcontainerはビルド済みイメージをECRに置いてInspectorに見張らせる.md`](../../ideas/2026-11-08-devcontainerはビルド済みイメージをECRに置いてInspectorに見張らせる.md)。

いまの `devcontainer-templates/` は Template を ghcr に publish している。
これを、ビルド済みのイメージを ECR に置いて各リポジトリから参照する形に変える案。
まだ試していない。

## 配り方の比較

| 方式 | 何を配るか | 配った後の更新の反映 | 主な用途 |
|---|---|---|---|
| `.devcontainer/` をコミット | 設定そのもの | git で全員に届く | チーム開発の標準 |
| ビルド済みイメージ | イメージ | digest を上げれば届く | 起動を速くし、中身をそろえる |
| Feature | ツールのインストール手順 | バージョンを上げれば届く | 複数リポジトリで共通のツールを入れる |
| Template（今） | 雛形 | 届かない（コピーで終わり） | 新しいプロジェクトの立ち上げ |

Template は一度コピーしたら元を更新しても届かないので、環境をそろえ続ける用途には向かない。
今の README の「Template ID を入れて Clone in Container Volume」は、毎回 URI を入力する手間もある。

イメージ方式なら、URI は `devcontainer.json` に一度書くだけ。
リポジトリを開けば「Reopen in Container」が出る。

## 構成

1. `devcontainers/ci` で今の Dockerfile と Features をビルドする
2. OIDC で認証して ECR に push する
3. ECR の拡張スキャンで Inspector がスキャンする
4. 各リポジトリの `devcontainer.json` は `image: <ECR の URI>@sha256:...` だけにする
5. digest は Renovate で上げる

`devcontainers/ci` でビルドすると、Features と設定がイメージのラベルに入る。
そのため利用側に `features:` を書かなくてよい。
書くと、開くたびにその分のレイヤーをローカルでビルドするので遅くなる。

## うれしいこと

### Inspector が見張り続ける

拡張スキャンは push 時に加えて、新しい CVE が出たときにも再スキャンする。
CI の Trivy は PR 時点のゲートとして残し、push 後に見つかったものは Inspector で拾う、という分担になる。

再スキャンを続ける期間は「push 日から」か「最後の pull から」で選べる。
使われ続けるイメージだけ見たいなら pull 基準がよい。

### 全員が同じ環境になる

digest で固定すると、更新は `devcontainer.json` の差分になる。
VS Code は `devcontainer.json` が変わると Rebuild を勧めてくるので、古いコンテナを使い続ける人が出にくい。
`latest` を参照すると、イメージが変わっても誰も気づかない。

### 初回の起動が速い

ビルドが pull に置き換わる。
2 回目以降に開くのは、もともと既存のコンテナの再利用なので変わらない。

速くならないもの。

- `post-create.sh`：コンテナを作るたびに走る
- VS Code の拡張機能：起動時に入る
- イメージが大きいと、初回の pull 自体に時間がかかる

### エージェントを閉じ込める箱になる

ホストの `~/.aws` や SSH 鍵が見えない環境で、Claude Code に許可確認なしで動いてもらえる。
壊されても作り直せばよい。
ADR 0004（ホストの認証情報をマウントしない）とも合う。

Claude app のクラウドセッションは自前のイメージを持ち込めず、セットアップスクリプトで毎回入れることになる。
app から使いたいなら、devcontainer の中で Claude Code を動かし、Remote Control で操作するほうが、スキャン済みのイメージを使える。

## 失うもの

### ツールを自分で入れる経験

インストールで覚えていたことのうち、失われるのは次のもの。

- ダウンロードして PATH を通す手順。覚える価値は低い
- バージョンをそろえる必要性。何もしなくてもそろってしまうので、気づきにくくなる

`terraform init` と `.terraform.lock.hcl`、`aws login` などの認証は、結局自分でやるので残る。

補い方。

- Dockerfile を読んでもらう。どこから入れて、なぜ SHA256 を検証しているかが全部書いてある
- 最初のタスクを「イメージのツールを 1 つ上げる PR」にする。固定・ハッシュ・Renovate・スキャン・Rebuild を一周できる

### ECR の手間と費用

- リポジトリは push だけでは作られないので、Terraform で先に作る
- `latest` などのタグを付け直すので、タグは mutable にする
- private ECR は匿名で pull できない。使う側も `docker login` が要り、トークンは 12 時間で切れる
- Inspector は初回スキャンと再スキャンがイメージ単位で課金される

### 中で好きに入れる自由

コンテナの中で入れたものは Rebuild で消える。
消えるのが嫌で Rebuild しない人が出ると、CVE 対応も届かなくなる。

締め付けるより、Rebuild しても困らない状態を作る。

| 置き場所 | 内容 |
|---|---|
| dotfiles | VS Code の `dotfiles.repository` に設定すると、コンテナを作るたびにクローンして実行される |
| `dev.containers.defaultFeatures` | VS Code のユーザー設定。個人用の Feature を全部のコンテナに足せる |
| イメージへの PR | 全員が手で入れているものは、イメージに入れるべきもの |

`sudo` を外して入れられなくするのはやりすぎ。試したいときに困る。

## 移すときに直すもの

`post-create.sh` で入れているもの（flake8・pylint・ansible・Terraform 本体など）は Inspector から見えない。
スキャン対象にしたいなら Dockerfile 側に寄せる。
ただし `uv tool install` のようにホームディレクトリに入れるものは、そのまま移すと動かないことがある。

Template の OCI artifact はイメージではないので、そもそもスキャンされない。

## 向いていない場面

- ツールのバージョンをそろえたいだけなら、mise や aqua のほうが軽い
- Mac では Docker のファイル I/O が遅く、大きいリポジトリだとつらい
- 一人で使い、エージェントにも強い権限を渡さないなら、恩恵は小さい
