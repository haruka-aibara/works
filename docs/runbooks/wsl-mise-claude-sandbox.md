# WSL + mise + Claude Code sandbox の開発環境

WSL には最小限の apt パッケージだけを入れる。
開発ツールはリポジトリごとの `mise.toml` / `mise.lock` で揃える。
Claude Code は sandbox の中で動かし、許可したドメインにだけ通信させる。

| 層 | 入るもの | 更新のしかた |
|---|---|---|
| WSL（apt） | git・curl・bubblewrap・socat・mise 本体 | unattended-upgrades が自動で当てる |
| mise（リポジトリごと） | terraform・aws-cli・gh・tflint・trivy など | `mise.toml` / `mise.lock` を PR で更新する |
| Claude Code | sandbox の中で動く | sandbox の外（ホーム配下）には書き込めない。ツールを足すときも `mise.toml` の diff として出てくる |

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
sudo apt install -y git curl ca-certificates bubblewrap socat
```

bubblewrap と socat は Claude Code の sandbox が使う。
ほかの開発ツールは apt では入れない。

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
```

シェルに組み込む。

```bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
exec bash
mise --version
```

### グローバル設定

```bash
mise settings minimum_release_age=3d
```

公開から 3 日たっていない版は入れない。
乗っ取られたリリースを掴みにくくするための設定で、mise の既定値は 24h。

## 4. リポジトリに `mise.toml` / `mise.lock` を置く

リポジトリのルートで、使うツールをバージョンを固定して足す。

```bash
cd ~/src/<リポジトリ>
mise use terraform@1.17.1 aws-cli@2 gh@2 tflint@0 trivy@0
```

`mise.toml` が作られる。
`aws-cli@2` のようにメジャーだけ書いた場合、実際のバージョンは `mise.lock` で固定される。

ロックの設定を `mise.toml` に足す。

```toml
[settings]
lockfile = true  # install / upgrade のたびに mise.lock を更新する
locked = true    # mise.lock にないバージョン・URL は入れない
```

ロックファイルを作る。

```bash
mise lock --platform linux-x64,linux-arm64,macos-arm64
```

`mise.lock` には、プラットフォームごとにダウンロード URL とチェックサムが記録される。
WSL 以外（Mac・CI）でも使うなら、そのプラットフォームも `--platform` に並べる。

個人用の上書きはコミットしない。

```bash
printf 'mise.local.toml\nmise.local.lock\n.mise/locks/mise.local/\n' >> .gitignore
```

コミットする。

```bash
git add mise.toml mise.lock .gitignore
git commit -m "mise でツールのバージョンを固定する"
```

`.mise/locks/` ができていたら、それもコミットする。

### 使う側

clone したら、リポジトリのルートで次を実行する。

```bash
mise install --locked
```

`mise.lock` に書かれたバージョンが、チェックサムを確かめたうえで入る。
terraform・aws-cli・gh・tflint・trivy は、mise の標準の aqua バックエンドで入る。
aqua バックエンドは、配布元が出しているチェックサム・GitHub の attestation・cosign・SLSA を検証する。

ディレクトリに入ると、そのリポジトリのバージョンに自動で切り替わる。

```bash
which terraform   # ~/.local/share/mise/installs/terraform/1.17.1/... を指す
terraform version
```

### バージョンを上げる

```bash
mise use terraform@1.18.0   # 固定しているバージョンを変える
mise lock --bump aws-cli    # aws-cli@2 の範囲で最新にする（mise.toml はそのまま）
mise install --locked
```

`mise.toml` と `mise.lock` の diff を PR に出す。
Renovate は `mise.toml` を読めるが、`mise.lock` を一緒に直すかは設定次第。
Renovate の PR で `mise.lock` が古いままなら、手元で `mise lock` を実行して追いコミットする。

## 5. Claude Code を入れる

公式のネイティブインストーラーで入れる。

```bash
curl -fsSL https://claude.ai/install.sh | bash
claude --version
```

ネイティブ版は自動で更新される。
sandbox の設定まわりは版によって挙動が変わるので、古い版のまま使わない。

## 6. Claude Code の sandbox 設定

`~/.claude/settings.json`（ユーザー設定）に書く。
`strictAllowlist` はユーザー設定か管理者設定にしか効かないので、リポジトリの `.claude/settings.json` には書かない。

```json
{
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": true,
    "allowUnsandboxedCommands": false,
    "autoAllowBashIfSandboxed": true,
    "network": {
      "strictAllowlist": true,
      "allowedDomains": [
        "github.com",
        "api.github.com",
        "codeload.github.com",
        "objects.githubusercontent.com",
        "release-assets.githubusercontent.com",
        "registry.terraform.io",
        "releases.hashicorp.com"
      ]
    }
  },
  "permissions": {
    "deny": [
      "WebSearch",
      "Bash(sudo *)"
    ]
  }
}
```

| キー | 効果 |
|---|---|
| `enabled` | Bash を sandbox の中で動かす。書き込めるのは作業ディレクトリの中だけになる |
| `failIfUnavailable` | bubblewrap が無いなどで sandbox が使えないとき、sandbox なしで動かさずに起動を止める |
| `allowUnsandboxedCommands: false` | 失敗したコマンドを「sandbox の外でやり直す」抜け道を閉じる |
| `autoAllowBashIfSandboxed` | sandbox の中のコマンドは確認なしで実行させる。外に出られないので確認を省ける |
| `network.strictAllowlist` | 許可リストにないドメインは、確認を出さずに拒否する |
| `network.allowedDomains` | 通信してよいドメイン。既定は空 |
| `permissions.deny` | sandbox の外で動くツール（WebSearch）と sudo を止める |

`sandbox.excludedCommands` は書かない。
ここに書いたコマンドは sandbox の外で動くので、抜け道になる。

### WebFetch について

WebFetch は Bash ではなく Claude Code のツールなので、sandbox のネットワーク制限とは別に権限で決まる。
既定では、ドメインごとに確認を求められる。
「今後も聞かない」を選ぶと `WebFetch(domain:...)` の許可ルールがローカル設定に保存される。
完全に止めたいなら、`permissions.deny` に `"WebFetch"` も足す。

### リポジトリごとにドメインを足す

AWS を触るリポジトリなど、そのリポジトリだけで要るドメインは、リポジトリの `.claude/settings.json` に書く。
リスト型の設定はユーザー設定と結合される。

```json
{
  "sandbox": {
    "network": {
      "allowedDomains": ["*.amazonaws.com"]
    }
  }
}
```

裏返すと、clone したリポジトリの `.claude/settings.json` が許可ドメインを広げられる。
他人のリポジトリで Claude Code を起動する前に、`.claude/settings.json` を見ておく。

## 7. 動作確認

リポジトリのルートで `claude` を起動し、`/sandbox` で有効になっていることを確認する。
そのうえで、Claude に次のコマンドを実行させる。

| 実行させるコマンド | 期待する結果 |
|---|---|
| `git status` / `git diff` | 動く |
| `terraform version` / `aws --version` | 動く（mise で入れたものが使われる） |
| `touch ~/sandbox-test` | 失敗する（作業ディレクトリの外） |
| `curl -sS https://example.com` | 失敗する（許可リストにない） |
| `curl -sS https://api.github.com` | 動く |
| `mise install` | 失敗する（`~/.local/share/mise` に書けない） |

最後の `mise install` が失敗するのは想定どおり。
Claude にできるのは `mise.toml` を書き換えるところまでで、実際に入れるのは自分が sandbox の外で `mise install --locked` を実行したときだけになる。

## sandbox の中で詰まりやすいところ

| 症状 | 原因と対処 |
|---|---|
| `git push` が通らない | SSH は通りにくい。HTTPS + `gh auth login` に寄せる。署名付きコミットや SSH が必要なら、push は自分で実行する |
| `terraform init` がプロバイダーを落とせない | `registry.terraform.io` と `releases.hashicorp.com` を許可しているか確認する。`~/.terraform.d` のプラグインキャッシュには書けないので、`.terraform/` に毎回落ちる |
| aws コマンドが認証エラーになる | ログインは自分で sandbox の外で実行する（`aws login`）。トークンの更新で `~/.aws` 配下に書けずに失敗するなら、`sandbox.filesystem.allowWrite` に必要なディレクトリだけ足す |
| `git config --global` が失敗する | `~/.gitconfig` は作業ディレクトリの外。自分で設定する |
