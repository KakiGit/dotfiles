if status is-interactive
    set -gx EDITOR nvim
    set -gx nvm_default_version (string match --regex '^v[0-9]+\.[0-9]+\.[0-9]+$' (path basename $nvm_data/v*) | sort -V | tail -n1)

    abbr --add nv "nvim"
    abbr --add lg "lazygit"
    abbr --add yz "yazi"
    abbr --add gst git status
    abbr --add gcm git commit
    abbr --add gaa git add --all
    abbr --add sb sandbox
    abbr --add asb "SANDBOX_TYPE=archlinux sandbox"
    abbr --add usb "SANDBOX_TYPE=ubuntu sandbox"
    abbr --add gpr git pull --rebase
    function sandbox
        if set -q SANDBOX_IN_CONTAINER
            echo "sandbox: already inside a sandbox container" >&2
            return 1
        end
        ~/sandbox/sandbox.sh $argv
    end

    function nvm-upgrade --description "Install and activate the latest stable Node"
        _nvm_index_update; or return
        set --local ver (string match --entire --regex '^v[0-9]+\.[0-9]+\.[0-9]+ ' <$nvm_data/.index | head --lines=1 | string split ' ')[1]
        test -n "$ver"; or return
        nvm install $ver
        set -gx nvm_default_version $ver
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


    function fish_greeting
        fastfetch
    end
    test -n "$nvm_default_version"; and nvm use --silent $nvm_default_version

end
