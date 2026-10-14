tags: android, scrcpy, adb, tools

# scrcpy は、端末にアプリを入れずに adb 経由で Android を画面共有・操作できる

scrcpy は Genymobile 製の OSS で、Android の画面を PC に映し、PC のキーボードとマウスで操作できる。
root も端末へのアプリインストールも要らない。
必要なのは、端末側で USB デバッグを有効にしておくことだけ。

仕組みは次のとおり。

- 起動時に小さなサーバー（jar）を adb で `/data/local/tmp` に送り込み、`app_process` で一時的に動かす
- 端末側で画面を H.264 などにエンコードし、adb のトンネルで PC に流す
- PC 側の入力はイベントとして端末に送り返す。終了するとサーバーも消える

画面共有以外にもできることがある。

- 音声の転送（Android 11 以降）
- 録画：`--record file.mp4`
- 見るだけ：`--no-control`（`-n`）
- Wi-Fi 越しの接続：`--tcpip`。最初の 1 回は USB でつなぐ
- カメラ映像を映す：`--video-source=camera`（Android 12 以降）
- 画面を映さず、PC のキーボード・マウスだけを物理 HID として使う：`--otg`

注意しておくこと。
USB デバッグを許可した PC は、端末に対して adb shell 相当の権限を持つ。
共用 PC で使ったあとは、開発者オプションで「USB デバッグ承認を取り消す」を押しておく。
