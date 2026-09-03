#!/bin/bash
set -euo pipefail

DEFAULT_IMAGE="docker.io/redroid/redroid:14.0.0_64only-latest"
DEFAULT_NAME="redroid14"
DEFAULT_PORT=5555
DEFAULT_DATA="/opt/redroid/data"
DEFAULT_WIDTH=1920
DEFAULT_HEIGHT=1080
DEFAULT_DPI=320
DEFAULT_FPS=60

IMAGE="${REDROID_IMAGE:-$DEFAULT_IMAGE}"
NAME="${REDROID_NAME:-$DEFAULT_NAME}"
PORT="${REDROID_PORT:-$DEFAULT_PORT}"
DATA="${REDROID_DATA:-$DEFAULT_DATA}"
WIDTH="${REDROID_WIDTH:-$DEFAULT_WIDTH}"
HEIGHT="${REDROID_HEIGHT:-$DEFAULT_HEIGHT}"
DPI="${REDROID_DPI:-$DEFAULT_DPI}"
FPS="${REDROID_FPS:-$DEFAULT_FPS}"
GPU="${REDROID_GPU:-}"
GPU_NODE="${REDROID_GPU_NODE:-/dev/dri/renderD129}"

die() {
    echo "error: $*" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage: redroid.sh --host <host_ssh_to> {setup|install|uninstall}

  setup      verify host prerequisites (read-only)
  install    create systemd unit and start redroid
  uninstall  stop redroid and remove the systemd unit

Env overrides: REDROID_IMAGE, REDROID_NAME, REDROID_PORT, REDROID_DATA,
               REDROID_WIDTH, REDROID_HEIGHT, REDROID_DPI, REDROID_FPS,
               REDROID_GPU (set to "all" for a Mesa-compatible GPU;
               NVIDIA is unsupported), REDROID_GPU_NODE
EOF
}

run_root() {
    local remote_tmp="$1"
    shift
    local local_tmp
    local_tmp="$(mktemp)"
    trap "rm -f '$local_tmp'" EXIT
    cat > "$local_tmp"
    scp -q "$local_tmp" "$HOST:$remote_tmp"
    ssh -t "$HOST" "sudo bash $remote_tmp ${*@Q}; rc=\$?; rm -f $remote_tmp; exit \$rc" </dev/tty
}

cmd_setup() {
    ssh -o BatchMode=yes "$HOST" bash -s <<'REMOTE'
set -euo pipefail
rc=0
check() {
    if "$@" >/dev/null 2>&1; then
        echo "ok    $*"
    else
        echo "FAIL  $*"
        rc=1
    fi
}
check grep -qE "nodev[[:space:]]+binder" /proc/filesystems
check zgrep -q "CONFIG_IPV6=y" /proc/config.gz
check zgrep -q "CONFIG_MEMFD_CREATE=y" /proc/config.gz
check test -d /dev/dma_heap
check command -v podman
exit $rc
REMOTE
}

cmd_install() {
    run_root /tmp/redroid-install.sh \
        "$IMAGE" "$NAME" "$PORT" "$DATA" "$WIDTH" "$HEIGHT" "$DPI" "$FPS" "$GPU" "$GPU_NODE" <<'REMOTE'
set -euo pipefail
image=$1; name=$2; port=$3; data=$4; width=$5; height=$6; dpi=$7; fps=$8; gpu=$9; gpu_node=${10}

mkdir -p "$data"

exec_start="/usr/bin/podman run --name $name --privileged -v $data:/data -p 127.0.0.1:$port:5555"
if [[ -n "$gpu" ]]; then
    exec_start+=" --gpus all"
fi
exec_start+=" $image androidboot.use_memfd=true androidboot.redroid_width=$width androidboot.redroid_height=$height androidboot.redroid_dpi=$dpi androidboot.redroid_fps=$fps"
if [[ -n "$gpu" ]]; then
    exec_start+=" androidboot.redroid_gpu_mode=host androidboot.redroid_gpu_node=$gpu_node"
fi

cat > /etc/systemd/system/redroid.service <<UNIT
[Unit]
Description=redroid Android container ($name)
After=network-online.target
Wants=network-online.target

[Service]
ExecStartPre=-/usr/bin/podman rm -f $name
ExecStart=$exec_start
ExecStop=/usr/bin/podman stop -t 10 $name
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable redroid.service
systemctl restart redroid.service

state=""
for _ in $(seq 1 30); do
    state=$(podman inspect --format '{{.State.Status}}' "$name" 2>/dev/null || true)
    [[ "$state" == "running" ]] && break
    sleep 2
done

echo
echo "container status: ${state:-starting (image may still be pulling)}"
echo "recent logs:"
podman logs --tail 20 "$name" 2>&1 || true
REMOTE
    print_usage
}

cmd_uninstall() {
    run_root /tmp/redroid-uninstall.sh "$NAME" "$DATA" <<'REMOTE'
set -euo pipefail
name=$1; data=$2

systemctl disable --now redroid.service 2>/dev/null || true
podman rm -f "$name" 2>/dev/null || true
rm -f /etc/systemd/system/redroid.service
systemctl daemon-reload

echo "redroid removed"
echo "note: data kept at $data (remove manually to purge)"
REMOTE
}

print_usage() {
    cat <<EOF

redroid installed. Connect from this machine:

  ssh -L $PORT:127.0.0.1:$PORT $HOST    # keep this open
  adb connect localhost:$PORT
  adb devices
  scrcpy -s localhost:$PORT

On the host: sudo systemctl status redroid
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --host) HOST="${2:?missing value for --host}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) break ;;
        esac
    done
    local action="${1:-}"

    [[ -n "${HOST:-}" ]] || die "missing --host"
    case "$action" in
        setup) cmd_setup ;;
        install) cmd_install ;;
        uninstall) cmd_uninstall ;;
        *) usage; exit 1 ;;
    esac
}

main "$@"
