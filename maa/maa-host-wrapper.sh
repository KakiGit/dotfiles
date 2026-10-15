#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${CONTAINER:-vol_sandbox_sandbox_1}"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/maa/host_wrapper.log"
START_ATTEMPTS=3
START_RETRY_SLEEP=20
SYSTEMCTL="/usr/bin/systemctl"
UNIT="redroid.service"

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }

start_redroid() {
    for ((attempt = 1; attempt <= START_ATTEMPTS; attempt++)); do
        if sudo "${SYSTEMCTL}" start "${UNIT}" >>"$LOG" 2>&1; then
            return 0
        fi
        log "startup attempt $attempt/$START_ATTEMPTS failed, restarting redroid"
        sudo "${SYSTEMCTL}" stop "${UNIT}" >>"$LOG" 2>&1 || true
        sleep "$START_RETRY_SLEEP"
    done
    return 1
}
stop_redroid() {
    sudo "${SYSTEMCTL}" stop "${UNIT}" >>"$LOG" 2>&1 || true
}

[ $# -gt 0 ] || { echo "usage: $0 <task> [task...]" >&2; exit 2; }
start_redroid || { log "not able to start redroid"; exit 1; }
trap stop_redroid EXIT
podman exec "$CONTAINER" bash -c 'export PATH="$HOME/.local/bin:$PATH"; exec maa-run-task "$@"' _ "$@"
