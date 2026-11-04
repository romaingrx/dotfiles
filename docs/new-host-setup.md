# New macOS host

`scripts/install.sh` installs Nix, clones to `~/.dotfiles`, and switches —
Homebrew, the SSH and GPG keys (via sops), and everything else come from the switch.

## Before

Copy the sops age key from another host to `~/.config/sops/age/keys.txt` (mode `0600`).
It's the only secret you carry over — the GPG and SSH keys decrypt from it on switch.

## Bootstrap

```sh
curl -fsSL https://romaingrx.com/dotfiles/install.sh | HOST=brobot bash
```

`HOST` defaults to `hostname -s`; the repo must land at `~/.dotfiles`.

## After

1. Grant Accessibility + Screen Recording when prompted: aerospace, sketchybar, jankyborders.
2. Set Arc as the default browser (System Settings).
3. Install `claude-code` (intentionally not in Nix, so it self-updates).

# Work laptop (`strato`)

`strato` is set up like any other host (same age key, same GitHub identity), plus
the `tl` work tooling in `hosts/darwin/strato/`.

## Before

Let the company MDM finish enrolling the laptop, then follow "Before" and "Bootstrap" above
with `HOST=strato`.

## After

1. AWS: `aws configure sso` with profile name `tl` (it is the default via
   `AWS_PROFILE`), then `aws sso login`.
2. Dev box: `ssh tl-devbox` finds the running box by its `owner-email` tag, read
   from the SSO session, so a rebuilt box needs no config change. Add your SSH
   public key to the box once first.
3. Tailscale: sign in with the work account and turn on Tailscale DNS.
4. Open OrbStack once so it links `docker` (see `modules/darwin/orbstack.nix`).
5. Install the `tl` CLIs by hand and sign in.
6. Claude Code: install as on other hosts.
