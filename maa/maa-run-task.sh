#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

CLIENT="Official"
MAA="$HOME/.local/bin/maa"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/maa/cron.log"
START_ATTEMPTS=3
START_RETRY_SLEEP=20
ADB_WAIT_TRIES=10
ADB_WAIT_SLEEP=5
UNLOCK_TRIES=5
UNLOCK_SLEEP=2

CONFIG_DIR="${MAA_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/maa}"
PROFILE="${MAA_PROFILE:-default}"

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }

profile_field() {
    local key="$1" file="$2"
    sed -nE "/^[[:space:]]*\"?$key\"?[[:space:]]*[:=]/ { s/.*\"([^\"]+)\".*/\1/p; q; }" "$file"
}

profile_file() {
    local base="$CONFIG_DIR/profiles/$PROFILE" f
    for f in "$base.json" "$base.toml" "$CONFIG_DIR/asst.toml"; do
        [ -f "$f" ] && { printf '%s\n' "$f"; return 0; }
    done
    return 1
}

PROFILE_FILE="$(profile_file || true)"
PRESET=""
ADDR="${ADB_ADDR:-}"
if [ -n "$PROFILE_FILE" ]; then
    PRESET="$(profile_field preset "$PROFILE_FILE")"
    [ -n "$ADDR" ] || ADDR="$(profile_field address "$PROFILE_FILE")"
fi
ADDR="${ADDR:-localhost:5555}"
PRESET="${PRESET:-ADB}"
[ -n "$PROFILE_FILE" ] || log "no maa profile found, falling back to $ADDR"

closedown() { "$MAA" closedown -a "$ADDR" "$CLIENT" >>"$LOG" 2>&1; }

keyguard_showing() {
    adb -s "$ADDR" shell dumpsys window 2>/dev/null | grep -q 'isKeyguardShowing=true'
}

wake_unlock() {
    adb -s "$ADDR" shell input keyevent 224
    adb -s "$ADDR" shell wm dismiss-keyguard >/dev/null 2>&1 || true
    local i
    for ((i = 0; i < UNLOCK_TRIES; i++)); do
        keyguard_showing || return 0
        sleep "$UNLOCK_SLEEP"
    done
    return 1
}

resize_screen() {
    adb -s "$ADDR" shell wm size 1080x1920
    SCREEN_RESIZED=1
    log "screen resized to 1080x1920"
}

reset_screen() {
    [ "${SCREEN_RESIZED:-0}" = 1 ] || return 0
    adb -s "$ADDR" shell wm size reset
    SCREEN_RESIZED=0
    log "screen resolution reset"
}

cleanup() {
    closedown
    reset_screen
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

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
        if "$MAA" startup -a "$ADDR" "$CLIENT" >>"$LOG" 2>&1; then
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
        if "$MAA" run -a "$ADDR" "$task" >>"$LOG" 2>&1; then
            log "task $task done"
        else
            log "task $task failed"
            status=1
        fi
    done
    return "$status"
}

[ $# -gt 0 ] || { echo "usage: $0 <task> [task...]" >&2; exit 2; }
if [ "$PRESET" = "ADB" ]; then
    wait_adb || { log "adb not reachable at $ADDR"; exit 1; }
    wake_unlock || { log "device still locked (Smart Lock not trusted?); aborting"; exit 1; }
    resize_screen
fi
start_game || { log "startup failed after $START_ATTEMPTS attempts"; exit 1; }
run_tasks "$@"
