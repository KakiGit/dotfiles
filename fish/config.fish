if status is-interactive
    set -gx EDITOR nvim

    alias nv="nvim"
    alias lg="lazygit"
    alias yz="yazi"

    fish_add_path $HOME/bin

    set -gx PYENV_ROOT $HOME/.pyenv
    fish_add_path $PYENV_ROOT/bin
    fish_add_path $HOME/.opencode/bin
    pyenv init - | source

    fzf --fish | source

    zoxide init fish | source

    starship init fish | source

    function fish_greeting
        fastfetch
    end

end
