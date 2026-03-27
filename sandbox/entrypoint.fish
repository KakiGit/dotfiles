#!/bin/fish

bash -c "$(curl -fsSL https://raw.githubusercontent.com/KakiGit/myZSH/master/setup.sh)" || true
curl -LsSf https://astral.sh/uv/install.sh | sh
curl -fsSL https://opencode.ai/install | bash
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fisher install jorgebucaran/nvm.fish
nvm install latest

exec sleep infinity
