#!/bin/bash
set -euo pipefail

DOTFILES_DIR="${HOME}/dotfiles"
REPO_URL="https://github.com/KakiGit/dotfiles"
DEFAULT_FEATURES="vim,fish,starship,fzf"
FEATURES="${FEATURES:-$DEFAULT_FEATURES}"

HOST="${DOTFILES_HOST:-$(hostname -s)}"
SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-${HOME}/.config/sops/age/keys.txt}"
SALT_FILE="${DOTFILES_DIR}/salt.sops.yaml"
INDEX_FILE="${DOTFILES_DIR}/index.sops.json"
ADMIN_PUB_FILE="${DOTFILES_DIR}/admin.pub"
HOSTS_DIR="${DOTFILES_DIR}/hosts"
HOST_ID_LEN=16

declare -A FEATURE_BINARIES=(
    [vim]="cmake make"
    [fish]="fish"
    [starship]="starship"
    [fzf]="git"
    [zsh]="zsh"
    [tmux]="tmux"
    [i3]="i3"
    [sway]="sway"
    [hypr]="Hyprland"
    [waybar]="waybar"
    [terminator]="terminator"
    [i3blocks]="i3blocks"
    [ghostty]="ghostty"
    [fcitx5]="fcitx5"
    [pulse]="pulseaudio pactl"
    [sandbox]="python3"
)

_git_clone_or_rebase() {
    local repo_url="$1"
    local target_dir="$2"
    local depth="${3:-}"

    if [[ -d "${target_dir}/.git" ]]; then
        git -C "${target_dir}" pull --rebase
    else
        if [[ -n "$depth" ]]; then
            git clone --depth "$depth" "$repo_url" "$target_dir"
        else
            git clone "$repo_url" "$target_dir"
        fi
    fi
}

_link_config() {
    local source="$1"
    local target="$2"

    if [[ -e "${target}" && ! -L "${target}" ]]; then
        local backup="${target}.bak.$(date +%s)"
        mv "${target}" "${backup}"
        echo "Backed up ${target} -> ${backup}"
    fi

    ln -snf "${source}" "${target}"
}

_scaffold_config() {
    local template="$1"
    local target="$2"

    if [[ -e "${target}" ]]; then
        return 0
    fi

    cp "${template}" "${target}"
    echo "Created ${target} (edit it for machine-specific settings)"
}

_require_sops() {
    for bin in sops age-keygen; do
        if ! command -v "${bin}" &> /dev/null; then
            echo "${bin} is required for encrypted host configs" >&2
            exit 1
        fi
    done
}

_load_salt() {
    sops --decrypt --extract '["salt"]' "${SALT_FILE}"
}

_host_id() {
    local host="${1:-${HOST}}" salt
    salt="$(_load_salt)"
    if command -v python3 &> /dev/null; then
        DOTFILES_SALT="${salt}" DOTFILES_HOST="${host}" DOTFILES_HOST_ID_LEN="${HOST_ID_LEN}" \
            python3 -c 'import os,hmac,hashlib,base64; s=os.environ["DOTFILES_SALT"].encode(); h=os.environ["DOTFILES_HOST"].encode(); n=int(os.environ["DOTFILES_HOST_ID_LEN"]); print(base64.b32encode(hmac.new(s,h,hashlib.sha256).digest()).decode().lower().rstrip("=")[:n])'
    else
        printf '%s' "${host}" \
            | openssl dgst -sha256 -hmac "${salt}" -binary \
            | base32 | tr 'A-Z' 'a-z' | tr -d '=' | cut -c1-"${HOST_ID_LEN}"
    fi
}

_sops_decrypt_to() {
    local src="$1"
    local target="$2"
    local -a args=()
    case "${src}" in
        *.sops.yaml) args=(--output-type yaml) ;;
        *.sops.json) args=(--output-type json) ;;
        *.sops.env)  args=(--output-type dotenv) ;;
        *.sops.ini)  args=(--output-type ini) ;;
        *)           args=(--input-type binary --output-type binary) ;;
    esac
    sops "${args[@]}" --decrypt "${src}" > "${target}.tmp.$$"
    mv "${target}.tmp.$$" "${target}"
}

_host_overlay_enabled() {
    [[ -z "${SANDBOX_IN_CONTAINER:-}" || -n "${DOTFILES_HOST_OVERLAY:-}" ]]
}

_setup_host_overlay() {
    local features="${1// /}"
    if ! _host_overlay_enabled; then
        echo "sandbox: skipping encrypted host overlay"
        return 0
    fi

    _require_sops

    if [[ ! -f "${SALT_FILE}" ]]; then
        echo "No ${SALT_FILE}; skipping host overlay"
        return 0
    fi
    if [[ ! -f "${SOPS_AGE_KEY_FILE}" ]]; then
        echo "No age key at ${SOPS_AGE_KEY_FILE}; skipping host overlay (run 'setup.sh bootstrap-identity')" >&2
        return 0
    fi

    local id host_root
    id="$(_host_id)"
    host_root="${HOSTS_DIR}/${id}"

    if [[ ! -d "${host_root}" ]]; then
        echo "No host config for id ${id} (host ${HOST}); nothing to overlay"
        return 0
    fi

    echo "Applying host overlay ${id} (host ${HOST})..."
    local src rel target mode app
    while IFS= read -r -d '' src; do
        rel="${src#"${host_root}/"}"
        app="${rel%%/*}"
        case ",${features}," in
            *,${app},*) ;;
            *) continue ;;
        esac
        target="${HOME}/.config/${rel%.sops}"
        case "${rel}" in
            secrets/*|*/secrets/*) mode="600" ;;
            *) mode="644" ;;
        esac
        mkdir -p "$(dirname "${target}")"
        _sops_decrypt_to "${src}" "${target}"
        chmod "${mode}" "${target}"
        echo "  ${rel} -> ${target}"
    done < <(find "${host_root}" -type f -name '*.sops' -print0 | sort -z)
}

_bootstrap_identity() {
    _require_sops
    if [[ -f "${SOPS_AGE_KEY_FILE}" ]]; then
        echo "Age key already exists at ${SOPS_AGE_KEY_FILE}"
    else
        mkdir -p "$(dirname "${SOPS_AGE_KEY_FILE}")"
        umask 077
        age-keygen -o "${SOPS_AGE_KEY_FILE}"
        echo "Created ${SOPS_AGE_KEY_FILE}"
    fi
    echo "Public key (send to an existing machine to register):"
    age-keygen -y "${SOPS_AGE_KEY_FILE}"
}

_admin_pubkey() {
    if [[ -f "${ADMIN_PUB_FILE}" ]]; then
        printf '%s\n' "$(< "${ADMIN_PUB_FILE}")"
    else
        age-keygen -y "${SOPS_AGE_KEY_FILE%/*}/admin-keys.txt"
    fi
}

_load_host_pubkeys() {
    _host_pubkeys=()
    local dir
    for dir in "${HOSTS_DIR}"/*/; do
        if [[ -f "${dir}pubkey" ]]; then
            _host_pubkeys+=("$(< "${dir}pubkey")")
        fi
    done
}

_emit_creation_rule() {
    local regex="$1"
    shift

    printf "  - path_regex: '%s'\n" "${regex}"
    printf '    key_groups:\n      - age:\n'
    local key
    for key in "$@"; do
        printf '          - %s\n' "${key}"
    done
}

_gen_sops_config() {
    local admin_pub="$1" dir id
    _load_host_pubkeys

    {
        printf '# Generated by setup.sh gen-sops-config; do not edit by hand.\n'
        printf 'creation_rules:\n'
        _emit_creation_rule '(^|/)salt\.sops\.yaml$' "${admin_pub}" "${_host_pubkeys[@]}"
        _emit_creation_rule '(^|/)index\.sops\.json$' "${admin_pub}"
        for dir in "${HOSTS_DIR}"/*/; do
            if [[ -f "${dir}pubkey" ]]; then
                id="$(basename "${dir}")"
                _emit_creation_rule "(^|/)hosts/${id}/" "${admin_pub}" "$(< "${dir}pubkey")"
            fi
        done
    } > "${DOTFILES_DIR}/.sops.yaml"

    echo "Wrote .sops.yaml"
}

_update_index() {
    local action="$1" id="$2" hostname="${3:-}" plaintext
    plaintext="$(mktemp)"

    if [[ -f "${INDEX_FILE}" ]]; then
        sops --output-type json --decrypt "${INDEX_FILE}" > "${plaintext}"
    else
        printf '{}\n' > "${plaintext}"
    fi

    python3 - "${plaintext}" "${action}" "${id}" "${hostname}" <<'PY'
import json
import sys

path, action, host_id, hostname = sys.argv[1:5]
data = json.load(open(path))
if action == "add":
    data[host_id] = hostname
elif action == "remove":
    data.pop(host_id, None)
json.dump(data, open(path, "w"), indent=2, sort_keys=True)
PY

    sops --input-type json --output-type json --encrypt --filename-override "${INDEX_FILE}" \
        "${plaintext}" > "${INDEX_FILE}.new"
    mv "${INDEX_FILE}.new" "${INDEX_FILE}"
    rm -f "${plaintext}"
}

_add_host() {
    local hostname="${1:-}" pubkey="${2:-}"
    if [[ -z "${hostname}" || -z "${pubkey}" ]]; then
        echo "usage: setup.sh add-host <hostname> <age-pubkey>" >&2
        exit 1
    fi

    local id
    id="$(_host_id "${hostname}")"

    mkdir -p "${HOSTS_DIR}/${id}"
    printf '%s\n' "${pubkey}" > "${HOSTS_DIR}/${id}/pubkey"
    _gen_sops_config "$(_admin_pubkey)"
    _update_index add "${id}" "${hostname}"
    sops updatekeys "${SALT_FILE}"

    echo "Registered '${hostname}' as ${id}."
    echo "Commit .sops.yaml, hosts/${id}/pubkey, salt.sops.yaml and index.sops.json"
}

_scaffold() {
    local rel="${1:-}"
    if [[ -z "${rel}" ]]; then
        echo "usage: setup.sh scaffold <app/relative/path>" >&2
        exit 1
    fi

    local template="${DOTFILES_DIR}/${rel}.example"
    local target="${HOSTS_DIR}/$(_host_id)/${rel}.sops"

    if [[ ! -f "${template}" ]]; then
        echo "No template ${template}" >&2
        exit 1
    fi
    if [[ -e "${target}" ]]; then
        echo "${target} already exists" >&2
        return 0
    fi

    mkdir -p "$(dirname "${target}")"
    cp "${template}" "${target}"
    sops --input-type binary --output-type binary --encrypt --in-place "${target}"
    echo "Created ${target}; edit with: sops ${target}"
}

_secure_admin_key() {
    local admin_file="${SOPS_AGE_KEY_FILE%/*}/admin-keys.txt"
    local output="${1:-${HOME}/Documents/admin-keys.txt.age}"

    if [[ ! -f "${admin_file}" ]]; then
        echo "No admin key at ${admin_file}" >&2
        exit 1
    fi

    mkdir -p "$(dirname "${output}")"
    age -p -o "${output}" "${admin_file}"
    if age -d "${output}" | diff -q - "${admin_file}" > /dev/null; then
        echo "Verified ${output}"
    else
        echo "Verification failed; keeping the plaintext key" >&2
        exit 1
    fi

    echo "Back up ${output} offsite and store the passphrase separately, then run:"
    echo "  shred -u ${admin_file}"
}

_check_binaries() {
    local features="$1"
    local -a required=("git" "curl")

    IFS=',' read -ra feature_array <<< "$features"
    for feature in "${feature_array[@]}"; do
        feature=$(echo "$feature" | tr -d ' ')
        if [[ -n "${FEATURE_BINARIES[$feature]:-}" ]]; then
            for bin in ${FEATURE_BINARIES[$feature]}; do
                required+=("$bin")
            done
        fi
    done

    if [[ -f "${SALT_FILE}" ]] && _host_overlay_enabled; then
        required+=("sops" "age-keygen")
    fi

    for req in "${required[@]}"; do
        if ! command -v "${req}" &> /dev/null; then
            echo "${req} is not installed in your machine"
            exit 1
        fi
    done
}

_clone_dotfiles() {
    if [[ -d "${DOTFILES_DIR}" && ! -d "${DOTFILES_DIR}/.git" ]]; then
        echo "dotfiles directory exists at ${DOTFILES_DIR} but is not a git repo, skipping"
    else
        _git_clone_or_rebase "${REPO_URL}" "${DOTFILES_DIR}"
    fi
}

_setup_vim() {
    mkdir -p ~/.vim_runtime/autoload
    ln -snf "${DOTFILES_DIR}/vim/my_configs.vim" "${HOME}/.vim_runtime/my_configs.vim"
    curl -fLo "${HOME}/.vim_runtime/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

_setup_fish() {
    mkdir -p ~/.config/fish
    ln -snf "${DOTFILES_DIR}/fish/config.fish" "${HOME}/.config/fish/config.fish"
}

_setup_starship() {
    ln -snf "${DOTFILES_DIR}/starship/starship.toml" "${HOME}/.config/starship.toml"
}

_setup_fzf() {
    _git_clone_or_rebase "https://github.com/junegunn/fzf.git" ~/.fzf 1
    ${HOME}/.fzf/install --all
}

_setup_zsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    local zsh_custom="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"
    _git_clone_or_rebase "https://github.com/bhilburn/powerlevel9k.git" ~/.oh-my-zsh/custom/themes/powerlevel9k
    _git_clone_or_rebase "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${zsh_custom}/plugins/zsh-syntax-highlighting"
    _git_clone_or_rebase "https://github.com/zsh-users/zsh-autosuggestions" "${zsh_custom}/plugins/zsh-autosuggestions"
    mkdir -p ~/.config/zsh/config.d
    ln -snf "${DOTFILES_DIR}/zsh/zshrc" "${HOME}/.zshrc"
}

_setup_tmux() {
    mkdir -p ~/.config/tmux/config.d
    ln -snf "${DOTFILES_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf"
}

_setup_i3() {
    mkdir -p ~/.config/i3/config.d
    ln -snf "${DOTFILES_DIR}/i3/config" "${HOME}/.config/i3/config"
}

_setup_sway() {
    local config_dir="${HOME}/.config/sway/config.d"

    mkdir -p "${config_dir}"
    _link_config "${DOTFILES_DIR}/sway/config" "${HOME}/.config/sway/config"
    _scaffold_config "${DOTFILES_DIR}/sway/config.d/monitor.conf.example" "${config_dir}/monitor.conf"
}

_setup_hypr() {
    mkdir -p ~/.config/hypr/config.d
    ln -snf "${DOTFILES_DIR}/hypr/hyprland.conf" "${HOME}/.config/hypr/hyprland.conf"
}

_setup_waybar() {
    local config_dir="${HOME}/.config/waybar/config.d"
    local scripts_dir="${HOME}/.config/waybar/scripts"

    mkdir -p "${config_dir}" "${scripts_dir}"
    _link_config "${DOTFILES_DIR}/waybar/config" "${HOME}/.config/waybar/config"
    _scaffold_config "${DOTFILES_DIR}/waybar/config.d/local.jsonc.example" "${config_dir}/local.jsonc"
    _link_config "${DOTFILES_DIR}/waybar/style.css" "${HOME}/.config/waybar/style.css"
    _link_config "${DOTFILES_DIR}/waybar/config-hypr" "${HOME}/.config/waybar/config-hypr"
    _link_config "${DOTFILES_DIR}/waybar/style-hypr.css" "${HOME}/.config/waybar/style-hypr.css"
    _link_config "${DOTFILES_DIR}/waybar/scripts/net-speed.sh" "${scripts_dir}/net-speed.sh"
}

_setup_terminator() {
    mkdir -p ~/.config/terminator
    ln -snf "${DOTFILES_DIR}/terminator/config" "${HOME}/.config/terminator/config"
}

_setup_i3blocks() {
    mkdir -p ~/.config/i3blocks
    ln -snf "${DOTFILES_DIR}/i3blocks/config" "${HOME}/.config/i3blocks/config"
    _git_clone_or_rebase "https://github.com/vivien/i3blocks-contrib.git" ~/.config/i3blocks-contrib
}

_setup_ghostty() {
    mkdir -p ~/.config/ghostty/config.d
    ln -snf "${DOTFILES_DIR}/ghostty/config.ghostty" "${HOME}/.config/ghostty/config"
}

_setup_fcitx5() {
    mkdir -p ~/.local/share/fcitx5
    _link_config "${DOTFILES_DIR}/fcitx5/config" "${HOME}/.config/fcitx5"
    _link_config "${DOTFILES_DIR}/fcitx5/rime" "${HOME}/.local/share/fcitx5/rime"
}

_setup_pulse() {
    mkdir -p ~/.config/pulse
    ln -snf "${DOTFILES_DIR}/pulse/default.pa" "${HOME}/.config/pulse/default.pa"
}

_setup_wechat() {
    mkdir -p "${HOME}/.local/bin"
    ln -snf "${DOTFILES_DIR}/wechat/wechat.sh" "${HOME}/.local/bin/wechat"
}

_setup_sandbox() {
    chmod +x "${DOTFILES_DIR}/sandbox/sandbox.sh" "${DOTFILES_DIR}/sandbox/sandbox.py"
    ln -sfn "${DOTFILES_DIR}/sandbox" "${HOME}/sandbox"
}

main() {
    _check_binaries "$FEATURES"
    _clone_dotfiles

    IFS=',' read -ra feature_array <<< "$FEATURES"
    for feature in "${feature_array[@]}"; do
        feature=$(echo "$feature" | tr -d ' ')
        if declare -f "_setup_${feature}" > /dev/null; then
            echo "Setting up ${feature}..."
            "_setup_${feature}"
        else
            echo "Warning: Unknown feature '${feature}'"
        fi
    done

    echo "Done!"

    _setup_host_overlay "${FEATURES}"
}

case "${1:-}" in
    "")
        main
        ;;
    host-id)
        _require_sops
        _host_id
        ;;
    host-overlay)
        _setup_host_overlay "${FEATURES}"
        ;;
    bootstrap-identity)
        _bootstrap_identity
        ;;
    scaffold)
        _require_sops
        _scaffold "${2:-}"
        ;;
    add-host)
        _require_sops
        _add_host "${2:-}" "${3:-}"
        ;;
    gen-sops-config)
        _require_sops
        _gen_sops_config "$(_admin_pubkey)"
        ;;
    secure-admin-key)
        _secure_admin_key "${2:-}"
        ;;
    *)
        echo "Usage: setup.sh [host-id|host-overlay|bootstrap-identity|scaffold <path>|add-host <hostname> <age-pubkey>|gen-sops-config|secure-admin-key <outfile>]" >&2
        exit 1
        ;;
esac
