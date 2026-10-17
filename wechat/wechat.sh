#!/bin/sh
# Launch WeChat inside the sandbox container with fcitx5 input-method support.
# WeChat's chat input lives in its Qt main shell, whose bundled fcitx plugin
# talks to this container's fcitx5 over D-Bus (client-side IME; candidates are
# drawn by classicui on the X11 display). fcitx5 here must NOT connect to the
# compositor: the host fcitx5 owns sway's input-method seat, and if this one
# binds it too, the embedded WeChatAppEx browser's IC steals focus from the
# chat input and typing breaks.
bus=unix:path=/tmp/dbus-session
export DBUS_SESSION_BUS_ADDRESS="$bus"
export QT_IM_MODULE=fcitx GTK_IM_MODULE=fcitx XMODIFIERS=@im=fcitx

[ -S /tmp/dbus-session ] || dbus-daemon --session --address="$bus" --fork
pgrep -x fcitx5 >/dev/null || { setsid env -u WAYLAND_DISPLAY fcitx5 -d >/tmp/fcitx5_container.log 2>&1 </dev/null & sleep 1; }

exec /opt/wechat/wechat "$@"
