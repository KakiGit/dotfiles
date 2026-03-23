#!/bin/bash
set -euo pipefail

REQ_BINARIES=("git" "cmake" "make" "curl" "zsh")
for req in "${REQ_BINARIES[@]}";
do
    if ! command -v "${req}" &> /dev/null
    then
        echo "${req} is not installed in your machine"
        exit
    fi
done

DOTFILES_DIR="${HOME}/dotfiles"
REPO_URL="https://github.com/KakiGit/dotfiles"

if [[ -d "${DOTFILES_DIR}" ]]; then
    echo "dotfiles repo already exists at ${DOTFILES_DIR}, skipping clone"
else
    git clone "${REPO_URL}" "${DOTFILES_DIR}"
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
${HOME}/.fzf/install --all

mkdir -p ~/.vim_runtime/autoload
mkdir -p ~/.config/fish
mkdir -p ~/.config/i3
mkdir -p ~/.config/sway
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/terminator
mkdir -p ~/.config/i3blocks

ln -snf "${DOTFILES_DIR}/zsh/zshrc" "${HOME}/.zshrc"
ln -snf "${DOTFILES_DIR}/vim/my_configs.vim" "${HOME}/.vim_runtime/my_configs.vim"
ln -snf "${DOTFILES_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf"
ln -snf "${DOTFILES_DIR}/fish/config.fish" "${HOME}/.config/fish/config.fish"
ln -snf "${DOTFILES_DIR}/i3/config" "${HOME}/.config/i3/config"
ln -snf "${DOTFILES_DIR}/sway/config" "${HOME}/.config/sway/config"
ln -snf "${DOTFILES_DIR}/hypr/hyprland.conf" "${HOME}/.config/hypr/hyprland.conf"
ln -snf "${DOTFILES_DIR}/waybar/config" "${HOME}/.config/waybar/config"
ln -snf "${DOTFILES_DIR}/waybar/style.css" "${HOME}/.config/waybar/style.css"
ln -snf "${DOTFILES_DIR}/waybar/config-hypr" "${HOME}/.config/waybar/config-hypr"
ln -snf "${DOTFILES_DIR}/waybar/style-hypr.css" "${HOME}/.config/waybar/style-hypr.css"
ln -snf "${DOTFILES_DIR}/terminator/config" "${HOME}/.config/terminator/config"
ln -snf "${DOTFILES_DIR}/starship/starship.toml" "${HOME}/.config/starship.toml"
ln -snf "${DOTFILES_DIR}/i3blocks/config" "${HOME}/.config/i3blocks/config"

curl -fLo "${HOME}/.vim_runtime/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

git clone https://github.com/vivien/i3blocks-contrib.git ~/.config/i3blocks-contrib