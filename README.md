## Install

`bash -c "$(curl -fsSL https://raw.githubusercontent.com/KakiGit/dotfiles/refs/heads/master/setup.sh)"`

## Host-specific and encrypted config

The repo is generic and public. Per-machine settings live in `hosts/<id>/`, where
`<id>` is an opaque id derived as `base32(HMAC-SHA256(salt, hostname))[:16]`, and
every host file is sops-encrypted. Hostnames and contents are therefore never
exposed in this repository.

`setup.sh` decrypts the matching host directory into `~/.config/...`, which the
generic configs include (`config.d/` for sway/waybar/i3/hypr, `conf.d/` for
fish, `source`/`config-file` for zsh/tmux/ghostty). Only apps selected via
`FEATURES` are decrypted and applied.

### Commands

- `setup.sh host-id` — print this machine's derived id
- `setup.sh host-overlay` — (re)apply this machine's decrypted config for the apps in `FEATURES`
- `setup.sh scaffold <app/path>` — create a host file from a `.example` template
- `sops-edit.sh <app/path>` — edit a host file in `$EDITOR`; re-encrypts it and redeploys to `~/.config/`
- `setup.sh bootstrap-identity` — generate this machine's age key
- `setup.sh add-host <hostname> <age-pubkey>` — register a machine (admin)
- `setup.sh gen-sops-config` — regenerate `.sops.yaml` (admin)
- `setup.sh secure-admin-key [outfile]` — encrypt the admin key for offline storage

### Adding a machine

1. On the new machine run `setup.sh bootstrap-identity`, then send its public key.
2. On a machine with the admin key run `setup.sh add-host <hostname> <age-pubkey>`.
3. On the new machine run `git pull && setup.sh`.

### Secrets and keys

Never commit plaintext. Keep the admin private key offline
(`setup.sh secure-admin-key`), store its passphrase separately, and back the
encrypted blob up offsite. Each machine holds only its own key at
`~/.config/sops/age/keys.txt`; only that host and the admin key can read its
directory.

### Sandboxes

The sandbox containers run `setup.sh` too, but their hostname is random and
must not become a new host id. The sandbox pins a stable identity
(`DOTFILES_HOST=sandbox`, `hostname: sandbox`) and, because it is detected via
`SANDBOX_IN_CONTAINER`, applies only the generic config — the encrypted host
overlay and secrets are skipped. Set `DOTFILES_HOST_OVERLAY=1` to opt in.

