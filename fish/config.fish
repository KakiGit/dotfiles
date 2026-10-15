if status is-interactive
    set -gx EDITOR nvim
    set -gx nvm_default_version latest

    abbr --add nv "nvim"
    abbr --add lg "lazygit"
    abbr --add yz "yazi"
    abbr --add gst git status
    abbr --add gcm git commit
    abbr --add gaa git add --all
    abbr --add sb sandbox
    abbr --add gpr git pull --rebase
    function sandbox
        if set -q SANDBOX_IN_CONTAINER
            echo "sandbox: already inside a sandbox container" >&2
            return 1
        end
        ~/sandbox/sandbox.sh $argv
    end

    fish_add_path $HOME/bin

    set -gx OPENCODE_EXPERIMENTAL_LSP_TY true
    set -gx PYENV_ROOT $HOME/.pyenv
    fish_add_path $PYENV_ROOT/bin
    fish_add_path $HOME/.opencode/bin
    fish_add_path $HOME/.bun/bin
    pyenv init - | source

    fzf --fish | source

    zoxide init fish | source

    starship init fish | source

    set -g fish_key_bindings fish_vi_key_bindings

    function fish_greeting
        fastfetch
    end
    nvm use latest

end
