# WSL + mise + Claude Code sandbox の開発環境

WSL には最小限の apt パッケージだけを入れる。
開発ツールは mise で入れ、版はファイルに書いておく。
Claude Code は sandbox の中で動かし、Bash は許可したドメインにだけ通信させ、認証情報は読ませない。

| 層 | 入るもの | 置き場所 | 更新のしかた |
|---|---|---|---|
| WSL（apt） | git・curl・bubblewrap・socat・mise 本体など | この手順書 | unattended-upgrades が自動で当てる |
| mise | terraform・aws-cli・gh・python まわりなど、そのリポジトリで使うもの | 各リポジトリの `mise.toml` | Renovate の PR |
| Claude Code | sandbox の設定 | 各リポジトリの `.claude/settings.json` | 手で直す |

以前は devcontainer テンプレートを ghcr に公開して同じことをしていた。
入れていたツールはこのリポジトリの `mise.toml` に、VS Code の設定などは `devenv/` に移してある（docker を除く）。Claude Code 本体と gcloud も mise で入れる。
コマンドはこのリポジトリの中で打つので、どこでも使えるようにする設定（mise のグローバル設定）は使わない。

## 1. Windows 側：WSL2 の Ubuntu を入れる

PowerShell で実行する。

```powershell
wsl --update
wsl --install -d Ubuntu-24.04
wsl -l -v
```

`VERSION` が `2` になっていることを確認する。
sandbox は WSL1 では動かない（`Sandboxing requires WSL2` と出る）。
1 になっていたら `wsl --set-version Ubuntu-24.04 2` で上げる。

## 2. WSL 側：最小限の apt パッケージ

以降は WSL の Ubuntu の中で実行する。

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git curl wget ca-certificates unzip zip htop tree bubblewrap socat libatomic1
```

bubblewrap と socat は Claude Code の sandbox が使う。
libatomic1 は mise で入れる node が使う。WSL の Ubuntu には最初から入っておらず、無いと node（と、それを使う Claude Code）の `mise install` が失敗する。
ほかの開発ツールは apt では入れない（jq・gcloud・Claude Code も mise）。

### systemd と自動更新

`unattended-upgrades` は systemd のタイマーで動く。
まず systemd が有効になっているか確認する。

```bash
cat /etc/wsl.conf
```

`[boot]` の下に `systemd=true` がなければ足す。

```ini
[boot]
systemd=true
```

足したら、PowerShell で `wsl --shutdown` を実行してから WSL を開き直す。

自動更新が動いているかを確認する。

```bash
systemctl status unattended-upgrades
sudo unattended-upgrade --dry-run --debug 2>&1 | tail -n 20
```

WSL を閉じている間はタイマーも止まり、次に開いたときに追いつく。

### Ubuntu Pro（任意・個人なら 5 台まで無料）

universe のパッケージにもセキュリティ修正（ESM）が届くようになる。
トークンは <https://ubuntu.com/pro/dashboard> で取得する。

```bash
sudo pro attach <トークン>
pro security-status
```

## 3. mise を入れる

公式の apt リポジトリから入れる。
`curl | sh` は使わない。

```bash
sudo apt install -y extrepo
sudo extrepo enable mise
sudo apt update
sudo apt install -y mise
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
exec bash
```

## 4. このリポジトリを clone する

```bash
git clone https://github.com/haruka-aibara/works ~/src/works
```

ツールは、このリポジトリに入ってコマンドを打ったときに入る（手順 6 の「使う側」）。

### mise で入れないもの

| ツール | 入れ方 | mise にしない理由 |
|---|---|---|
| docker | Docker Desktop の「Settings → Resources → WSL integration」で有効にする | デーモンが動いて初めて使える。mise で入るのはコマンドだけ |
| bubblewrap・socat | 手順 2 の apt | mise に登録が無い。sandbox が OS の部品として使う |
| mise 本体 | 手順 3 の apt | mise を入れるための mise は無い |

gcloud は mise の vfox プラグイン（mise の作者が作っているもの）で入る。
aqua バックエンドと違い、配布元のチェックサムや署名の確認はない。

## 5. VS Code の拡張機能と設定

VS Code の WSL 拡張でつないだターミナルで実行する。

```bash
xargs -n1 code --install-extension < ~/src/works/devenv/vscode/extensions.txt
mkdir -p ~/.local/state/crossnote
cp ~/src/works/devenv/crossnote/head.html ~/.local/state/crossnote/
```

`head.html` は、Markdown Preview Enhanced の Mermaid で AWS などのアイコンを使うための設定。

エディタの設定は `devenv/vscode/settings.json` にある。
コマンドパレットの「Preferences: Open User Settings (JSON)」を開き、中身をマージする。

## 6. リポジトリにツールを固定する

使うツールを、リポジトリのルートの `mise.toml` に書く。

```bash
cd ~/src/<リポジトリ>
mise use terraform@1.17.1 tflint@0.66.0
```

版は `"2"` や `"latest"` のような範囲にせず、正確に固定する。
範囲で書くと、実際の版は `mise.lock` を見ないと分からず、メジャー更新も `mise.lock` の差分に埋もれる。

`mise.toml` には `[tools]` だけを書く。
`[settings]` などを書くと、clone した人が最初に `mise trust` を求められる。

`mise.lock` は自動ではできないので、最初の 1 回だけ `mise lock` で作る。
一度できれば、以後は mise と Renovate が更新する。
WSL 以外（Mac・CI）でも使うなら、プラットフォームを足しておく。

```bash
mise lock --platform linux-x64,linux-arm64,macos-arm64
git add mise.toml mise.lock
git commit -m "mise でツールのバージョンを固定する"
```

`.mise/locks/` ができていたら、それもコミットする。
個人用の上書きはコミットしない。

```bash
printf 'mise.local.toml\nmise.local.lock\n.mise/locks/mise.local/\n' >> .gitignore
```

### 使う側

clone したときと `git pull` したときに、`mise install` を打つ。

```bash
cd ~/src/<リポジトリ>
git pull && mise install
```

mise を有効にしたシェルでは、見つからないコマンドが mise の一覧にあるツールなら、その場で入れてから実行もする（`not_found_auto_install`、既定で有効）。
ただし、`npm:` や `pypi:` で書いたツール（Claude Code・Python 製のツール）は一度入れるまで対象にならず、版が上がったときも古い版が入っていれば入れ直さない。
なので `mise install` を打つ前提にしている。

入れるときは、配布元が出しているチェックサム・GitHub の attestation・cosign・SLSA を確かめる（mise の aqua バックエンド）。
`mise.lock` にあるハッシュと合わなければ入らない。

### バージョンの更新

Renovate が `mise.toml` と `mise.lock` を同じ PR で更新する。
版を固定しているので、どの版からどの版に上がるかが `mise.toml` の差分で見える。
人がやるのは PR を見てマージすることだけで、次にコマンドを打ったときに新しい版が入る。

`renovate.json` で、mise のツールは公開から 3 日たったものだけ出すようにしている。
mise 自身も、公開から 24 時間たっていない版は入れない（`minimum_release_age` の既定値）。

aqua バックエンドのツールは、Renovate のドキュメントで「追加の設定が要る場合がある」扱いになっている。
新しいツールを足したら、Renovate の Dependency Dashboard に載ったかを一度確かめる。

## 7. Claude Code

Claude Code も `mise.toml` に書いてあり、このリポジトリで `claude` と打てば入る。
npm 版（`npm:@anthropic-ai/claude-code`）で入れている。npm 版は公式の入れ方の 1 つで、中身はネイティブ版と同じバイナリ（[Claude Code: Setup](https://code.claude.com/docs/en/setup)）。
mise は npm パッケージのスクリプトを既定で実行しないが、Claude Code は `postinstall` で本体のバイナリをつなぐので、`mise.toml` の `allow_builds` で Claude Code 自身のスクリプトだけ許可している（[mise: npm backend](https://mise.jdx.dev/dev-tools/backends/npm.html)）。
これが無いと、`claude` を打ったときに `claude native binary not installed` と出る。
本体は版が固定された別パッケージ（`@anthropic-ai/claude-code-linux-x64` など）から入るので、スクリプトが最新版を取ってくることはない。
リポジトリの外では起動しない。

Claude Code の自動更新は、`.claude/settings.json` の `env` に `DISABLE_UPDATES` を入れて止めている。
止めないと、mise で固定した版と実際に動く版がずれる。
版の更新は、ほかのツールと同じく Renovate の PR で行う。
Claude Code はほぼ毎日リリースされるので、Renovate は npm の `stable` の印が付いた版だけを PR にする（`renovate.json` の `followTag`）。
stable は、だいたい 1 週間前の版で、大きな不具合のある版は飛ばされる（[Claude Code: Setup](https://code.claude.com/docs/en/setup)）。
sandbox の設定まわりは版によって挙動が変わるので、Renovate の PR は溜めずにマージする。

## 8. Claude Code の設定

### 考え方

プロンプトインジェクションは防げない前提で組む。
注入で実害が出るのは、次の 3 つが同じセッションに揃ったときだけなので、どれかを欠く。

1. 信用できない内容を読む（WebFetch・clone したリポジトリ・Issue）
2. 秘密に触れる（`~/.aws`・gh のトークン・`.env`、プライベートリポジトリならコードそのもの）
3. 外へ送れる（Bash の通信・WebFetch・許可済みドメインへの push）

| 足 | どうするか |
|---|---|
| 1. 信用できない内容 | 基本は止めない。止め切れないし、止めると仕事にならない |
| 2. 秘密 | **一番固くする。** 認証情報は Claude から読めなくする |
| 3. 外への送信 | Bash は許可ドメインだけに絞る。WebFetch は公開リポジトリなら絞らず、プライベートリポジトリでは止める |

これは Simon Willison の「lethal trifecta」と、Meta の「Agents Rule of Two」の考え方そのもの。
設定は Trail of Bits の [claude-code-config](https://github.com/trailofbits/claude-code-config) を下敷きにして、WSL 向けに足している。

### 設定ファイルの置き場所

設定は、このリポジトリの `.claude/settings.json` に書いてある。
clone して Claude Code を起動すれば、それだけで効く。

ほかのリポジトリでも同じにしたいときは、このファイルをそのリポジトリの `.claude/settings.json` にコピーする（`language` は好みで消す）。
ユーザー設定（`~/.claude/settings.json`）には置かない。
置き場所を 1 つにして、どのリポジトリで何が効いているかを、そのリポジトリを見れば分かるようにするため。

### 各設定の意味

**sandbox（Bash を閉じ込める）**

| キー | 効果 |
|---|---|
| `enabled` | Bash を sandbox の中で動かす。書き込めるのは作業ディレクトリの中だけになる |
| `allowUnsandboxedCommands: false` | 失敗したコマンドを「sandbox の外でやり直す」抜け道を閉じる |
| `autoAllowBashIfSandboxed` | sandbox の中のコマンドは確認なしで実行させる。外に出られないので確認を省ける |
| `network.allowedDomains` | Bash から確認なしで通信してよいドメイン。既定は空 |

許可リストにないドメインへの通信は、拒否ではなく確認が出る。
確認に「Yes」と答えると、そのセッションの間はそのドメインに確認なしで通信できる。
「Yes, and don't ask again」を選ぶと許可ルールが保存され、次のセッションからも確認が出なくなるので、選ばない（[Claude Code: Sandboxing](https://code.claude.com/docs/en/sandboxing)）。
毎回必ず確認を出す設定は無い。

`sandbox.excludedCommands` は書かない。
ここに書いたコマンドは sandbox の外で動くので、抜け道になる。

**`Read(...)` の deny（秘密を読ませない）**

sandbox の既定では、読み取りは自由で `~/.aws` も `~/.ssh` も読める。
`Read(...)` の deny は Claude の Read ツールを止めるだけでなく、sandbox が有効なら OS のレベルで Bash の読み取りにも効く。
sandbox が無いと Bash からは素通りするので、必ず両方を使う。

WSL で特に効くのが `Read(//mnt/c/**)`。
WSL からは Windows 側のドライブがそのまま見えるので、`C:\Users\<名前>\.aws` などを読まれないように丸ごと塞ぐ。
`//` で始めると絶対パスになる。

**`Edit(...)` の deny（バックドアを仕込ませない）**

`~/.bashrc` や `~/.profile` に 1 行足されると、次に開いたシェルで sandbox の外で実行される。
sandbox は Bash からの書き込みを止めるが、Claude の Edit ツールで作業ディレクトリの外を書こうとすると確認が出るだけなので、deny で確認なしに止める。

**`Bash(...)` の deny と hook（うっかりを止める）**

この 2 つはコマンドの文字列で判定するので、書き方を変えれば抜けられる。
注入への防御ではなく、事故防止のガードレールとして入れている。
本当の防御は、sandbox と `Read` の deny が担う。

### WebFetch（公開リポジトリ）

WebFetch は Bash ではなく Claude Code のツールなので、sandbox のネットワーク制限は効かない。
ただし見に行くサイトは際限なく増えるので、許可リストで管理し切るのは現実的ではない。

公開リポジトリでは、秘密を読めない状態にしたうえで、WebFetch は既定の動き（新しいドメインでは確認が出る）のまま使う。

- 確認には「Yes（このセッションだけ）」で答える。同じセッションで同じドメインは二度聞かれない
- URL に見覚えのないクエリが付いているときは「No」にする。データを持ち出そうとしている形
- 「今後も聞かない」は、よく使うドキュメントのサイト以外では選ばない

注入されても漏れうるのは作業中のコードくらいで、それはもともと公開されている。

### プライベートリポジトリ

プライベートリポジトリでは、コードそのものが秘密になる。
Claude はコードを読まないと仕事にならないので、「秘密を断つ」が使えない。
代わりに「外への送信」を断つ。

リポジトリの `.claude/settings.json` で WebFetch を止める。
deny はユーザー設定と結合され、allow より優先される。

```json
{
  "permissions": {
    "deny": ["WebFetch"]
  }
}
```

公式ドキュメントくらいは読ませたいなら、deny の代わりに、使うサイトだけを許可する。
1 つのリポジトリで要るサイトは数個なので、リポジトリ単位なら管理できる。
それ以外のドメインでは確認が出るので、そこで止める。

```json
{
  "permissions": {
    "allow": [
      "WebFetch(domain:docs.aws.amazon.com)",
      "WebFetch(domain:developer.hashicorp.com)"
    ]
  }
}
```

Web の調べものは、リポジトリを開いていない空のディレクトリで起動した別の Claude にやらせ、結論だけを持ち込む。
1 つのセッションで持つ性質を 2 つまでにする、Rule of Two の形。

Bash の許可ドメインにワイルドカードを使わない。
`*.amazonaws.com` を許可すると、攻撃者の S3 バケットへの署名付き URL に PUT されれば、コードを持ち出せる。
`sts.ap-northeast-1.amazonaws.com` のように、使うエンドポイントだけを書く。

`github.com` と `api.github.com` は、認証情報を読めない状態なら書き込み（push・gist の作成）に使えないので、許可したままでよい。

### aws と gh

`~/.aws` と `~/.config/gh` を読めなくしているので、sandbox の中の Claude は aws と gh を認証付きでは使えない。
これは意図どおり。

- `aws login`・`gh auth login`・`git push` は自分で、Claude の外のターミナルで実行する
- Claude に AWS を触らせたいリポジトリだけ、読み取り専用ロールの短命な認証情報を別に用意する。普段使いの認証情報は渡さない
- Claude に push させたいなら、対象リポジトリだけに絞った fine-grained token を使い、main はブランチ保護で守る

### リポジトリごとにドメインを足す

そのリポジトリだけで要るドメインは、リポジトリの `.claude/settings.json` に書く。
リスト型の設定はユーザー設定と結合される。

```json
{
  "sandbox": {
    "network": {
      "allowedDomains": ["sts.ap-northeast-1.amazonaws.com"]
    }
  }
}
```

裏返すと、clone したリポジトリの `.claude/settings.json` が許可ドメインを広げられる。
他人のリポジトリで Claude Code を起動する前に、`.claude/settings.json` と `.mcp.json` を見ておく。

## 9. 動作確認

リポジトリのルートで `claude` を起動し、`/sandbox` で有効になっていることを確認する。
そのうえで、Claude に次のコマンドを実行させる。

| 実行させるコマンド | 期待する結果 |
|---|---|
| `git status` / `git diff` / `git commit` | 動く |
| `terraform version` / `aws --version` | 動く（mise で入れたものが使われる） |
| `touch ~/sandbox-test` | 失敗する（作業ディレクトリの外） |
| `cat ~/.aws/config` | 失敗する（`Read` の deny） |
| `ls /mnt/c/Users` | 失敗する（`Read` の deny） |
| `curl -sS https://example.com` | 確認が出る（許可リストにない）。「No」で止まる |
| `curl -sS https://api.github.com` | 動く |
| `git push origin main` | hook で止まる |
| `mise install` | 失敗する（`~/.local/share/mise` に書けない） |

最後の `mise install` が失敗するのは想定どおり。
Claude にできるのは `mise.toml` を書き換えるところまでで、実際に入れるのは自分のシェルでコマンドを打ったときだけになる。
新しく clone したリポジトリでは、Claude を起動する前に自分のシェルで `mise install` しておく。

## sandbox の中で詰まりやすいところ

| 症状 | 原因と対処 |
|---|---|
| Claude Code が起動しない（sandbox が使えない） | `/sandbox` の Dependencies タブに出ているものを入れる。AppArmor の制限と出たら [公式の手順](https://code.claude.com/docs/en/sandboxing#add-an-apparmor-profile-for-bubblewrap) どおりにする |
| PR に必須チェックの `Terraform Cloud/...` が付かず、マージできない | HCP Terraform と GitHub の連携が切れている。HCP Terraform で GitHub の連携を再認証してから、PR に push し直す |
| `git push` が通らない | 認証情報を読めないので想定どおり。push は自分で実行する |
| `terraform init` がプロバイダーを落とせない | `registry.terraform.io` と `releases.hashicorp.com` を許可しているか確認する。`~/.terraform.d` のプラグインキャッシュには書けないので、`.terraform/` に毎回落ちる |
| aws コマンドが認証エラーになる | `~/.aws` を読めないので想定どおり。Claude に使わせるなら、上の「aws と gh」のとおり専用の認証情報を用意する |
| `git config --global` が失敗する | `~/.gitconfig` は作業ディレクトリの外。自分で設定する |
| Windows 側のファイルを読ませたい | `Read(//mnt/c/**)` で塞いでいる。必要なファイルだけ WSL 側のリポジトリにコピーする |

## 参考

- [Simon Willison: lethal trifecta](https://simonwillison.net/tags/lethal-trifecta)
- [Meta: Agents Rule of Two](https://ai.meta.com/blog/practical-ai-agent-security/)
- [Anthropic: Beyond permission prompts](https://www.anthropic.com/engineering/claude-code-sandboxing)
- [Claude Code: Sandboxing](https://code.claude.com/docs/en/sandboxing)
- [mise: Lockfile](https://mise.jdx.dev/dev-tools/mise-lock.html)
- [Renovate: mise manager](https://docs.renovatebot.com/modules/manager/mise/)
- [trailofbits/claude-code-config](https://github.com/trailofbits/claude-code-config)
