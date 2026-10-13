#!/bin/bash
# 初回起動時のみ実行される（cloud-init）。2回目以降は systemd が全部起動する。
# Terraform の templatefile を通すので、bash の変数は $VAR と書き、波括弧付きの形は使わない。
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
# dbus-user-session: waydroid session がユーザーの session bus を使う
# dnsmasq-base / iptables: waydroid-net.sh がコンテナのネットワークを作るのに使う
apt-get install -y curl ca-certificates weston socat lxc python3 \
  dbus-user-session dnsmasq-base iptables adb
# binder_linux は aws カーネルだと modules-extra 側にある。
# メタパッケージも入れて、カーネル更新後の再起動でもモジュールが付いてくるようにする
apt-get install -y linux-modules-extra-aws "linux-modules-extra-$(uname -r)" || true
snap install aws-cli --classic

# ---------- binder ----------
# Ubuntu のカーネルは binderfs 対応で、デバイスは Waydroid が binderfs をマウントして作る
echo binder_linux > /etc/modules-load.d/binder.conf
modprobe binder_linux
grep -q binder /proc/filesystems || { echo "binderfs が使えないカーネル" >&2; exit 1; }

# ---------- Waydroid（arm64 / Google Play 付き） ----------
curl -fsSL https://repo.waydro.id | bash
apt-get install -y waydroid
waydroid init -s GAPPS

# GPU なし（/dev/dri が無い）→ ソフトウェア描画。
# waydroid_base.prop は waydroid upgrade で作り直されるので、waydroid.cfg の [properties] に書いて反映させる
python3 - <<'PY'
import configparser
p = "/var/lib/waydroid/waydroid.cfg"
c = configparser.ConfigParser()
c.optionxform = str
c.read(p)
if not c.has_section("properties"):
    c.add_section("properties")
c["properties"]["ro.hardware.gralloc"] = "default"
c["properties"]["ro.hardware.egl"] = "swiftshader"
with open(p, "w") as f:
    c.write(f)
PY
waydroid upgrade --offline

# ---------- 実行ユーザー ----------
id android >/dev/null 2>&1 || useradd -m -s /bin/bash android
UID_ANDROID=$(id -u android)
# 起動時に user@UID.service（/run/user/UID と session bus）を立てる
loginctl enable-linger android

# ---------- systemd: headless weston ----------
# 画面は scrcpy が Android 側から直接取るので、weston は Waydroid の描画先として居ればよい。
# headless の既定 renderer は noop なので、バッファを実際に受け取れる pixman を指定する
cat > /etc/systemd/system/weston-headless.service <<EOF
[Unit]
Description=Headless Weston for Waydroid
After=user@$UID_ANDROID.service
Requires=user@$UID_ANDROID.service

[Service]
User=android
Environment=XDG_RUNTIME_DIR=/run/user/$UID_ANDROID
ExecStart=/usr/bin/weston --backend=headless --renderer=pixman --socket=wayland-1 --width=720 --height=1280 --idle-time=0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# ---------- systemd: Waydroid session ----------
# show-full-ui はセッションが RUNNING になってから叩く（固定 sleep だと初回や重いときに外れる）
cat > /usr/local/bin/waydroid-show-ui.sh <<'EOF'
#!/bin/sh
i=0
until waydroid status 2>/dev/null | grep -Eq 'Session:[[:space:]]+RUNNING'; do
  i=$((i + 1))
  [ "$i" -ge 60 ] && { echo "session が RUNNING にならない" >&2; exit 1; }
  sleep 2
done
exec waydroid show-full-ui
EOF
chmod +x /usr/local/bin/waydroid-show-ui.sh

cat > /etc/systemd/system/waydroid-session.service <<EOF
[Unit]
Description=Waydroid session
After=waydroid-container.service weston-headless.service user@$UID_ANDROID.service
Requires=waydroid-container.service weston-headless.service user@$UID_ANDROID.service

[Service]
User=android
Environment=XDG_RUNTIME_DIR=/run/user/$UID_ANDROID
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$UID_ANDROID/bus
Environment=WAYLAND_DISPLAY=wayland-1
ExecStart=/usr/bin/waydroid session start
ExecStartPost=-/usr/local/bin/waydroid-show-ui.sh
ExecStop=/usr/bin/waydroid session stop
TimeoutStartSec=180
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------- adb を Tailscale の IP だけに公開 ----------
cat > /usr/local/bin/waydroid-adb-forward.sh <<'EOF'
#!/bin/sh
until TS_IP=$(tailscale ip -4 2>/dev/null) && [ -n "$TS_IP" ]; do sleep 2; done
exec socat TCP-LISTEN:5555,bind=$TS_IP,reuseaddr,fork TCP:192.168.240.112:5555
EOF
chmod +x /usr/local/bin/waydroid-adb-forward.sh

cat > /etc/systemd/system/waydroid-adb-forward.service <<'EOF'
[Unit]
Description=Forward adb (tailscale IP:5555 -> Waydroid)
After=waydroid-session.service tailscaled.service
Requires=tailscaled.service

[Service]
ExecStart=/usr/local/bin/waydroid-adb-forward.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# ---------- Tailscale ----------
curl -fsSL https://tailscale.com/install.sh | sh

# SSM のパラメータは Terraform がダミー値で作り、本物の auth key は後から手で上書きする。
# 本物が入るまで待って参加する。参加済みなら何もしない（auth key は1回使えば要らない）
cat > /usr/local/bin/tailscale-join.sh <<'EOF'
#!/bin/sh
until tailscale ip -4 >/dev/null 2>&1; do
  TS_KEY=$(/snap/bin/aws ssm get-parameter --name "${ts_param}" --with-decryption \
    --query Parameter.Value --output text --region "${region}" 2>/dev/null)
  case "$TS_KEY" in
    tskey-*) tailscale up --auth-key "$TS_KEY" --hostname waydroid || sleep 60 ;;
    *) echo "SSM ${ts_param} にまだ auth key が入っていない" >&2; sleep 60 ;;
  esac
done
EOF
chmod +x /usr/local/bin/tailscale-join.sh

cat > /etc/systemd/system/tailscale-join.service <<'EOF'
[Unit]
Description=Join tailnet with the auth key in SSM
After=tailscaled.service network-online.target
Wants=network-online.target
Requires=tailscaled.service

[Service]
Type=simple
ExecStart=/usr/local/bin/tailscale-join.sh

[Install]
WantedBy=multi-user.target
EOF

# ---------- 有効化 ----------
systemctl daemon-reload
systemctl enable --now waydroid-container.service
systemctl enable --now weston-headless.service
systemctl enable --now waydroid-session.service
systemctl enable --now tailscale-join.service
systemctl enable --now waydroid-adb-forward.service
