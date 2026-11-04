# strato

Trajectory Labs work laptop, named after Jimmy's Strato XL rocket. Same GitHub
identity as the other hosts, but per-device keys: the sops age key never lands
here (`dotfiles.secrets.enable = false`), so nothing personal decrypts on a
company-managed machine.

## Setup

1. Let the company MDM finish enrolling the laptop.
2. Bootstrap without the age key (the installer reads `dotfiles.secrets.enable`
   from strato's config and skips the check):
   `curl -fsSL https://romaingrx.com/dotfiles/install.sh | HOST=strato bash`

## Keys (once)

SSH, one key per purpose, each with a passphrase kept in 1Password. The agent
(gpg-agent, `enableSshSupport`) caches it after first use (`AddKeysToAgent`):

```sh
ssh-keygen -t ed25519 -f ~/.ssh/github -C strato
ssh-keygen -t ed25519 -f ~/.ssh/tl-devbox -C strato
gh auth login
gh ssh-key add ~/.ssh/github.pub --title strato
```

GPG signing subkey, created on a host that holds the full key (goddard):

```sh
gpg --quick-add-key 383E2222E1BEFDAD ed25519 sign 2y
gpg --list-keys --with-subkey-fingerprints 383E2222E1BEFDAD
gpg --armor --export-secret-subkeys '<SUBKEY_FPR>!' > strato.asc
gpg --delete-secret-keys '<SUBKEY_FPR>!'   # else goddard signs with it too
gpg --armor --export 383E2222E1BEFDAD   # re-upload on GitHub
```

Move `strato.asc` over through 1Password, `gpg --import strato.asc`, then delete
the file. `gpg -K` on strato shows `sec#`: the primary key is not there. When
done with the laptop, revoke the subkey on goddard (`gpg --edit-key`, `key N`,
`revkey`), re-upload the public key and remove the `strato` SSH key on GitHub.

## After the first switch

1. AWS: `aws configure sso` with profile name `tl` (it is the default via
   `AWS_PROFILE`), then `aws sso login`.
2. Dev box: `ssh tl-devbox` finds the running box by its `owner-email` tag, read
   from the SSO session, so the SSH config survives a rebuild. Add
   `~/.ssh/tl-devbox.pub` to the box's `authorized_keys` first; after a rebuild,
   add it again and run `ssh-keygen -R tl-devbox` (new host key).
   On the box, apply the `devbox` home-manager profile (no keys):
   `git clone https://github.com/romaingrx/dotfiles ~/.dotfiles && ~/.dotfiles/devcontainer.sh devbox`,
   then put your work email in `~/.config/git/work.gitconfig` (`[user] email = ...`).
3. Tailscale: sign in with the work account and turn on Tailscale DNS.
4. Open OrbStack once so it links `docker` (see `modules/darwin/orbstack.nix`).
5. Install the `tl` CLIs by hand and sign in.
