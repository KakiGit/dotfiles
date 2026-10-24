#!/bin/sh
set -eu

iface=$(ip route show default 2>/dev/null | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }')
if [ -z "$iface" ]; then
    printf '0B/s 0B/s\n'
    exit 0
fi

counters=$(awk -v dev="$iface" '$1 == dev":" { print $2, $10; exit }' /proc/net/dev)
if [ -z "$counters" ]; then
    printf '0B/s 0B/s\n'
    exit 0
fi

rx=${counters% *}
tx=${counters#* }
now=$(date +%s%N)

state_dir="${XDG_RUNTIME_DIR:-/tmp}"
state_file="${state_dir}/waybar-net-speed.${iface}"

up=0
down=0
if [ -r "$state_file" ]; then
    read -r prev_now prev_rx prev_tx < "$state_file" || true
    if [ -n "${prev_now:-}" ]; then
        dt=$(( (now - prev_now) / 1000000000 ))
        [ "$dt" -gt 0 ] || dt=1
        down=$(( (rx - prev_rx) / dt ))
        up=$(( (tx - prev_tx) / dt ))
        [ "$down" -ge 0 ] || down=0
        [ "$up" -ge 0 ] || up=0
    fi
fi
printf '%s %s %s\n' "$now" "$rx" "$tx" > "$state_file"

humanize() {
    awk -v b="$1" 'BEGIN {
        n = split("B/s kB/s MB/s GB/s TB/s", u, " ")
        i = 1
        while (b >= 1000 && i < n) { b /= 1000; i++ }
        printf "%d%s", b, u[i]
    }'
}

printf '%s %s\n' "$(humanize "$up")" "$(humanize "$down")"
