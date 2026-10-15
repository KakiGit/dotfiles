#!/usr/bin/env bash
set -euo pipefail

if [ -n "${SANDBOX_IN_CONTAINER:-}" ]; then
    echo "sandbox: already inside a sandbox container; refusing to nest" >&2
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd)"
export SANDBOX_SCRIPT_DIR="$SCRIPT_DIR"
export SANDBOX_TYPE="${SANDBOX_TYPE:-archlinux}"
export SANDBOX_ROOT="${SANDBOX_ROOT:-$HOME/sandbox}"
export SANDBOX_DIR="${SANDBOX_ROOT}/${SANDBOX_TYPE}"
VENV="${SANDBOX_VENV:-$SANDBOX_ROOT/.venv}"

[ -d "$SCRIPT_DIR/$SANDBOX_TYPE" ] \
    || { echo "sandbox: unknown SANDBOX_TYPE '$SANDBOX_TYPE'" >&2; exit 2; }

mkdir -p "$SANDBOX_ROOT" "$SANDBOX_DIR"
if [ ! -x "$VENV/bin/python" ]; then
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install --quiet --upgrade pyyaml
fi

exec "$VENV/bin/python" "$SCRIPT_DIR/sandbox.py" "$@"
