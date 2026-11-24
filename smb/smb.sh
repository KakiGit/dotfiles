#!/bin/bash
# smb.sh — systemd automount units for the SMB shares declared in mounts.conf.
#
#   ./smb.sh        install/update units in /etc/systemd/system (uses sudo)
#   ./smb.sh dry    render units to ${SMB_UNIT_DIR:-/tmp/smb-units} only
#
# mounts.conf (host overlay: hosts/<id>/smb/mounts.conf.sops) contains one
# mount_share call per share:
#
#   mount_share <name> <//server/share> </absolute/mountpoint> [extra cifs options]
#
# $HOME in the conf is the invoking user's home. smb.sh always applies
# vers=3.1.1, uid/gid, noexec, nosuid, nodev and iocharset=utf8; extra options
# are appended, so "ro" wins where it matters and "credentials=<account>"
# expands to ~/.config/smb/secrets/<account> (decrypted by the host overlay,
# mode 0600).

set -euo pipefail

die() { echo "smb: $*" >&2; exit 1; }

MODE="${1:-apply}"
case "$MODE" in
    apply|dry) ;;
    *) die "unknown mode '$MODE' (use apply or dry)" ;;
esac
UNIT_DIR="${SMB_UNIT_DIR:-/etc/systemd/system}"
IDLE_TIMEOUT="${SMB_IDLE_TIMEOUT:-600}"
STATE_FILE="${UNIT_DIR}/smb-dotfiles.units"

declare -a SHARES=() UNITS=() AUTOMOUNTS=()

if [[ "$MODE" == "apply" && $EUID -ne 0 ]]; then
    exec sudo bash "$(readlink -f "${BASH_SOURCE[0]}")" apply
fi

USER_UID="${SUDO_UID:-$(id -u)}"
USER_GID="${SUDO_GID:-$(id -g)}"
USER_HOME="$(getent passwd "$USER_UID" | cut -d: -f6)"
CONF="${SMB_CONF:-${USER_HOME}/.config/smb/mounts.conf}"
CREDS_DIR="${SMB_CREDS_DIR:-${USER_HOME}/.config/smb/secrets}"

mount_share() { SHARES+=("$1|$2|$3|${4:-}"); }

load_shares() {
    [[ -f "$CONF" ]] || die "no $CONF (create with: setup.sh scaffold smb/mounts.conf)"
    HOME="$USER_HOME"
    # shellcheck disable=SC1090
    source "$CONF"
    [[ ${#SHARES[@]} -gt 0 ]] || die "no mount_share() lines in $CONF"
}

install_share() {
    local name="$1" what="$2" where="$3" extra="${4:-}" opts unit auto
    [[ "$where" == /* ]] || die "mountpoint must be absolute: $where"
    extra="$(sed -E "s#credentials=([^/,][^,]*)#credentials=${CREDS_DIR}/\1#g" <<<"$extra")"
    opts="vers=3.1.1,uid=${USER_UID},gid=${USER_GID},noexec,nosuid,nodev,iocharset=utf8${extra:+,$extra}"
    unit="$(systemd-escape -p --suffix=mount "$where")"
    auto="$(systemd-escape -p --suffix=automount "$where")"

    cat > "${UNIT_DIR}/${unit}" <<EOF
[Unit]
Description=SMB share ${name} (${what})

[Mount]
What=${what}
Where=${where}
Type=cifs
Options=${opts}
EOF

    cat > "${UNIT_DIR}/${auto}" <<EOF
[Unit]
Description=Automount SMB share ${name} (${where})

[Automount]
Where=${where}
TimeoutIdleSec=${IDLE_TIMEOUT}

[Install]
WantedBy=multi-user.target
EOF

    UNITS+=("$unit" "$auto")
    AUTOMOUNTS+=("$auto")
    echo "wrote ${UNIT_DIR}/${unit}"
}

prune_removed() {
    local u
    touch "$STATE_FILE"
    while read -r u; do
        systemctl disable --now --quiet "$u" 2>/dev/null || true
        rm -f "${UNIT_DIR}/${u}"
        echo "removed ${UNIT_DIR}/${u}"
    done < <(comm -23 <(sort "$STATE_FILE") <(printf '%s\n' "${UNITS[@]}" | sort))
    printf '%s\n' "${UNITS[@]}" | sort > "$STATE_FILE"
}

main() {
    command -v systemd-escape >/dev/null || die "systemd-escape not found"
    load_shares
    mkdir -p "$UNIT_DIR"

    local i
    for i in "${!SHARES[@]}"; do
        IFS='|' read -r name what where extra <<<"${SHARES[$i]}"
        install_share "$name" "$what" "$where" "$extra"
    done

    if [[ "$MODE" != "apply" ]]; then
        return 0
    fi
    command -v mount.cifs >/dev/null || [[ -x /usr/sbin/mount.cifs ]] \
        || [[ -x /sbin/mount.cifs ]] || die "install cifs-utils"
    prune_removed
    systemctl daemon-reload
    local u
    for u in "${AUTOMOUNTS[@]}"; do
        systemctl enable --now --quiet "$u"
    done
}

main
