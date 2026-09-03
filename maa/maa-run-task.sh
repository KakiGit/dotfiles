#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

CLIENT="Official"
ADDR="localhost:5555"
MAA="$HOME/.local/bin/maa"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/maa/cron.log"
START_ATTEMPTS=3
START_RETRY_SLEEP=20
ADB_WAIT_TRIES=10
ADB_WAIT_SLEEP=5

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }


closedown() { "$MAA" closedown "$CLIENT" >>"$LOG" 2>&1; }
trap closedown EXIT

wait_adb() {
    local i
    for ((i = 0; i < ADB_WAIT_TRIES; i++)); do
        if adb -s "$ADDR" get-state >/dev/null 2>&1; then
            return 0
        fi
        adb connect "$ADDR" >/dev/null 2>&1 || true
        sleep "$ADB_WAIT_SLEEP"
    done
    return 1
}

start_game() {
    local attempt
    for ((attempt = 1; attempt <= START_ATTEMPTS; attempt++)); do
        if "$MAA" startup "$CLIENT" >>"$LOG" 2>&1; then
            return 0
        fi
        log "startup attempt $attempt/$START_ATTEMPTS failed, restarting app"
        closedown
        sleep "$START_RETRY_SLEEP"
    done
    return 1
}

run_tasks() {
    local task status=0
    for task in "$@"; do
        if "$MAA" run "$task" >>"$LOG" 2>&1; then
            log "task $task done"
        else
            log "task $task failed"
            status=1
        fi
    done
    return "$status"
}

[ $# -gt 0 ] || { echo "usage: $0 <task> [task...]" >&2; exit 2; }
wait_adb || { log "adb not reachable at $ADDR"; exit 1; }
start_game || { log "startup failed after $START_ATTEMPTS attempts"; exit 1; }
run_tasks "$@"
