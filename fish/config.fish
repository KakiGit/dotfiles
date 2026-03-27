if status is-interactive
    set -gx EDITOR nvim
    set -gx nvm_default_version v25.8.2

    abbr --add nv "nvim"
    abbr --add lg "lazygit"
    abbr --add yz "yazi"
    abbr --add gst git status
    abbr --add gcmsg git commit -m
    abbr --add gaa git add --all
    abbr --add sb sandbox
    function sandbox
        set container (podman ps --filter name=sandbox_sandbox_1 --format '{{.Names}}' | head -n1)
        if test -n "$container"
            podman exec -ti $container fish
        else
            echo "container not found"
        end
    end

    fish_add_path $HOME/bin

    set -gx PYENV_ROOT $HOME/.pyenv
    fish_add_path $PYENV_ROOT/bin
    fish_add_path $HOME/.opencode/bin
    pyenv init - | source

    fzf --fish | source

    zoxide init fish | source

    starship init fish | source

    set -g fish_key_bindings fish_vi_key_bindings

    function fish_greeting
        fastfetch
    end

end
