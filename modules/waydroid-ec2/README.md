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

Tailscale の auth key は state に残さないため、SSM パラメータ（`/waydroid/ts_authkey`）は Terraform がダミー値で作り、本物は手で上書きする。
インスタンスは本物の key が入るまで 1 分おきに見に行き、入ったら Tailscale に参加する（`tailscale-join.service`）。
apply の前後どちらで入れてもよい。

```bash
aws ssm put-parameter --region ap-northeast-1 --overwrite \
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

## 初回だけ手でやること

Waydroid の adb は接続のたびに Android 側の許可ダイアログを出すが、scrcpy で繋ぐ前なので押せない（`unauthorized` になる）。
手元 PC の公開鍵を、SSM で入って Android の中に直接書き込む。

```powershell
Get-Content $HOME\.android\adbkey.pub | Set-Clipboard   # 手元 PC
```

```bash
sudo waydroid shell   # インスタンス。以下は Android の中
echo '<貼る>' >> /data/misc/adb/adb_keys
chown system:shell /data/misc/adb/adb_keys
chmod 640 /data/misc/adb/adb_keys
exit
```

鍵は EBS 上に残るので、止めて起動し直してもやり直さなくてよい。

## scrcpy のオプション

- `--no-audio`：インスタンスにオーディオを入れていないので音は出ない
- `--video-encoder=c2.android.avc.encoder`：Waydroid のイメージは Codec2 を無効にしていて、残る OMX のエンコーダは scrcpy の Surface 入力で落ちる。user_data で `debug.stagefright.ccodec=4` にして Codec2 を使わせている

## 未検証のところ

- **ソフトウェア描画の重さ**：動画の多い画面がどこまで滑らかに出るか

## うまく動かないとき

SSM で入って順に見る。

```bash
aws ssm start-session --target <instance_id>
sudo tail -n 100 /var/log/cloud-init-output.log
sudo systemctl status tailscale-join weston-headless waydroid-container waydroid-session waydroid-adb-forward
sudo waydroid status
adb connect 192.168.240.112:5555 && adb devices   # インスタンス内から直接
```

- **`unauthorized` になる**：上の「初回だけ手でやること」をやる
- **scrcpy が `CodecException: Error 0x80001001` で落ちる**：`scrcpy --list-encoders` に `c2.android.*` が無ければ Codec2 が無効のまま。`sudo waydroid shell -- getprop debug.stagefright.ccodec` が `4` か見る
- **scrcpy が真っ黒**： `sudo -u android XDG_RUNTIME_DIR=/run/user/$(id -u android) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u android)/bus waydroid show-full-ui`
- **「Play プロテクト認定を受けていません」と出る**：`sudo waydroid shell` で Android ID を取り、google.com/android/uncertified で登録する
- **重い**：`instance_type = "c7g.2xlarge"`（料金は約 2 倍）
