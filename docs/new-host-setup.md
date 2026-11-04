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

# Work host (`strato`)

`strato` is the work laptop. It is built with `identity = "work"` (`flake.nix`),
so it skips the personal sops, GPG and GitHub SSH keys: do not copy the age key
onto it. Employer-specific values stay on the machine, not in this repo.

## Before

1. Let the company MDM finish enrolment (nothing here configures it).
2. Make the work SSH key: `ssh-keygen -t ed25519`. Add `~/.ssh/id_ed25519.pub` to
   GitHub twice, as an authentication key and as a signing key (commits sign with it).

## Bootstrap

```sh
curl -fsSL https://romaingrx.com/dotfiles/install.sh | HOST=strato bash
```

## After

1. Git email: create `~/.config/git/work.gitconfig` with `[user] email = <work email>`.
2. AWS: `aws configure sso` with profile name `work` (it is the default via
   `AWS_PROFILE`), then `aws sso login`.
3. Dev box: `ssh devbox` finds the running box by its `owner-email` tag (your work
   git email), so a rebuilt box needs no config change. Add the public key to the
   box once first.
4. Tailscale: sign in with the work account and turn on Tailscale DNS.
5. Open OrbStack once so it links `docker` (see `modules/darwin/orbstack.nix`).
6. Install `claude-code` as on other hosts, and any work CLIs by hand.
