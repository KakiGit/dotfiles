#!/bin/bash
set -euo pipefail

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
if [[ -f ${HOME}/.zshrc ]];
then
    mv "${HOME}/.zshrc"  "${HOME}/zshrc.bk$(date '+%y%m%d%H')"
fi
curl -o "${HOME}/.zshrc" https://raw.githubusercontent.com/KakiGit/dotfiles/master/zshrc
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
${HOME}/.fzf/install --all
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
curl -o "${HOME}/.vim_runtime/my_configs.vim" https://raw.githubusercontent.com/KakiGit/dotfiles/master/my_configs.vim
curl -o "${HOME}/.tmux.conf" https://raw.githubusercontent.com/KakiGit/dotfiles/master/tmux.conf
