#!/bin/sh
# Launch WeChat inside the sandbox container with fcitx5 input-method support.
# WeChat's Qt shell talks to fcitx5 over D-Bus, so a session bus and a fcitx5
# daemon must be running first.
bus=unix:path=/tmp/dbus-session
export DBUS_SESSION_BUS_ADDRESS="$bus"
export QT_IM_MODULE=fcitx GTK_IM_MODULE=fcitx XMODIFIERS=@im=fcitx

[ -S /tmp/dbus-session ] || dbus-daemon --session --address="$bus" --fork
pgrep -x fcitx5 >/dev/null || { setsid fcitx5 -d >/tmp/fcitx5_container.log 2>&1 </dev/null & sleep 1; }

exec /opt/wechat/wechat "$@"
