# New macOS host

`scripts/install.sh` installs Nix, clones to `~/.dotfiles`, and switches —
Homebrew, the SSH and GPG keys (via sops), and everything else come from the switch.

## Before

Copy the sops age key from another host to `~/.config/sops/age/keys.txt` (mode `0600`).
It's the only secret you carry over — the GPG and SSH keys decrypt from it on switch.

## Bootstrap

```sh
curl -fsSL https://raw.githubusercontent.com/romaingrx/dotfiles/main/scripts/install.sh | HOST=brobot bash
```

`HOST` defaults to `hostname -s`; the repo must land at `~/.dotfiles`.

## After

1. Grant Accessibility + Screen Recording when prompted: aerospace, sketchybar, jankyborders.
2. Set Arc as the default browser (System Settings).
3. Install `claude-code` (intentionally not in Nix, so it self-updates).
