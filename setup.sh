#!/bin/bash
set -euo pipefail

DOTFILES_DIR="${HOME}/dotfiles"
REPO_URL="https://github.com/KakiGit/dotfiles"
DEFAULT_FEATURES="vim,fish,starship,fzf"
FEATURES="${FEATURES:-$DEFAULT_FEATURES}"

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
)

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
    
    for req in "${required[@]}"; do
        if ! command -v "${req}" &> /dev/null; then
            echo "${req} is not installed in your machine"
            exit 1
        fi
    done
}

_clone_dotfiles() {
    if [[ -d "${DOTFILES_DIR}" ]]; then
        echo "dotfiles repo already exists at ${DOTFILES_DIR}, skipping clone"
    else
        git clone "${REPO_URL}" "${DOTFILES_DIR}"
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
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ${HOME}/.fzf/install --all
}

_setup_zsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    ln -snf "${DOTFILES_DIR}/zsh/zshrc" "${HOME}/.zshrc"
}

_setup_tmux() {
    ln -snf "${DOTFILES_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf"
}

_setup_i3() {
    mkdir -p ~/.config/i3
    ln -snf "${DOTFILES_DIR}/i3/config" "${HOME}/.config/i3/config"
}

_setup_sway() {
    mkdir -p ~/.config/sway
    ln -snf "${DOTFILES_DIR}/sway/config" "${HOME}/.config/sway/config"
}

_setup_hypr() {
    mkdir -p ~/.config/hypr
    ln -snf "${DOTFILES_DIR}/hypr/hyprland.conf" "${HOME}/.config/hypr/hyprland.conf"
}

_setup_waybar() {
    mkdir -p ~/.config/waybar
    ln -snf "${DOTFILES_DIR}/waybar/config" "${HOME}/.config/waybar/config"
    ln -snf "${DOTFILES_DIR}/waybar/style.css" "${HOME}/.config/waybar/style.css"
    ln -snf "${DOTFILES_DIR}/waybar/config-hypr" "${HOME}/.config/waybar/config-hypr"
    ln -snf "${DOTFILES_DIR}/waybar/style-hypr.css" "${HOME}/.config/waybar/style-hypr.css"
}

_setup_terminator() {
    mkdir -p ~/.config/terminator
    ln -snf "${DOTFILES_DIR}/terminator/config" "${HOME}/.config/terminator/config"
}

_setup_i3blocks() {
    mkdir -p ~/.config/i3blocks
    ln -snf "${DOTFILES_DIR}/i3blocks/config" "${HOME}/.config/i3blocks/config"
    git clone https://github.com/vivien/i3blocks-contrib.git ~/.config/i3blocks-contrib
}

_setup_ghostty() {
    mkdir -p ~/.config/ghostty
    ln -snf "${DOTFILES_DIR}/ghostty/config.ghostty" "${HOME}/.config/ghostty/config"
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
}

main