#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${DOTFILES_DIR}"

die() {
    echo "$*" >&2
    exit 1
}

deploy() {
    local encrypted="$1" rel="$2"
    local target="${HOME}/.config/${rel}" mode="644"
    case "${rel}" in
        secrets/*|*/secrets/*) mode="600" ;;
    esac
    mkdir -p "$(dirname "${target}")"
    sops --decrypt "${encrypted}" > "${target}.tmp.$$"
    chmod "${mode}" "${target}.tmp.$$"
    mv "${target}.tmp.$$" "${target}"
    echo "Deployed ${rel} -> ${target}"
}

main() {
    local rel="${1:-}"
    [[ -n "${rel}" ]] || die "usage: sops-edit.sh <app/relative/path>"
    rel="${rel%.sops}"

    local encrypted="${DOTFILES_DIR}/hosts/$(bash "${DOTFILES_DIR}/setup.sh" host-id)/${rel}.sops"
    [[ -f "${encrypted}" ]] || die "${encrypted} not found; create it with: setup.sh scaffold ${rel}"

    local status=0
    sops "${encrypted}" || status=$?
    case "${status}" in
        0)   deploy "${encrypted}" "${rel}" ;;
        200) echo "No changes; skipping redeploy" ;;
        *)   die "sops edit failed (exit ${status})" ;;
    esac
}

main "$@"
