# waydroid-ec2

EC2（Graviton）の上で Waydroid を動かし、手元の PC から Tailscale 越しに scrcpy で触るクラウド Android 環境。
使うときだけ手動で起動・停止する。

> ⚠️ まだ一度も apply していない。
> 下の「未検証のところ」は実機で確かめるまで推測。

## 構成

```text
[EC2 c7g.xlarge / Ubuntu 24.04 arm64]  ※インバウンド全閉
  weston (headless)  ← Waydroid の描画先。GPU なしなのでソフトウェア描画
  Waydroid           ← 192.168.240.112:5555 で adb を待つ
  socat              ← <Tailscale の IP>:5555 → 192.168.240.112:5555
  tailscaled
        ↓
[手元 PC] Tailscale + adb + scrcpy
```

Graviton にしたのは、Android の ARM 向けアプリを変換レイヤなしで動かすため。
Waydroid はコンテナ（LXC）なので、ネストした仮想化も metal インスタンスも要らない。

## 事前準備

Tailscale の auth key は state に残さないため、Terraform では作らず SSM に手で入れる。
**main にマージする前に入れておく。** マージすると HCP Terraform がそのまま apply し、key が無いとインスタンスは立つが Tailscale に参加できない。

```bash
aws ssm put-parameter --region ap-northeast-1 \
  --name /waydroid/ts_authkey --type SecureString --value 'tskey-auth-xxxx'
```

auth key は Reusable / Ephemeral どちらも off でよい。
参加したあと、Tailscale の管理画面で `waydroid` の key expiry を無効にしておく（既定の 180 日で切れると繋がらなくなる）。

手元の PC には Tailscale と scrcpy（Windows は GitHub の Genymobile/scrcpy の zip に adb が同梱）を入れておく。

## 使い方

初回は Waydroid のイメージ取得があるので、apply から 10〜15 分かかる。
Tailscale の管理画面に `waydroid` が出てきたら、ワークスペースの output `waydroid_ec2.connect` のコマンドで繋ぐ。

起動・停止は Terraform を通さず、output の `manual_start` / `manual_stop` のコマンドを手元で叩く。
止めている間も EBS（40GB で月 $4 弱）はかかる。
`ignore_changes = [ami, user_data]` にしているのは、EBS 上の Android のデータ（アプリのログイン状態）を作り直しで消さないため。
ルートの `module "waydroid_ec2"` を外すと EBS ごと消える。

## 未検証のところ

- **binder**：aws カーネルで `binder_linux` が `linux-modules-extra-aws` 側にある前提。無ければ cloud-init が binder のところで止まる
- **ソフトウェア描画**：arm64 の Waydroid イメージに swiftshader が入っている前提で `ro.hardware.egl=swiftshader` を入れている
- **adb の認証**：Waydroid のイメージ次第で、接続時に許可ダイアログが出て `unauthorized` になるかもしれない
- **scrcpy の映像**：Waydroid にはハードウェアエンコーダが無いので、ソフトウェアエンコーダで映像が出るか

## うまく動かないとき

SSM で入って順に見る。

```bash
aws ssm start-session --target <instance_id>
sudo tail -n 100 /var/log/cloud-init-output.log
sudo systemctl status weston-headless waydroid-container waydroid-session waydroid-adb-forward
sudo waydroid status
adb connect 192.168.240.112:5555 && adb devices   # インスタンス内から直接
```

- **`unauthorized` になる**：手元 PC の `~/.android/adbkey.pub` の中身を、インスタンスの `/home/android/.local/share/waydroid/data/misc/adb/adb_keys` に追記してから `sudo systemctl restart waydroid-session`
- **scrcpy が真っ黒**：エンコーダを明示する（`scrcpy --list-encoders` で名前を見て `--video-codec=h264 --video-encoder=c2.android.avc.encoder` など）。それでもだめなら `sudo -u android XDG_RUNTIME_DIR=/run/user/$(id -u android) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u android)/bus waydroid show-full-ui`
- **「Play プロテクト認定を受けていません」と出る**：`sudo waydroid shell` で Android ID を取り、google.com/android/uncertified で登録する
- **重い**：`instance_type = "c7g.2xlarge"`（料金は約 2 倍）
