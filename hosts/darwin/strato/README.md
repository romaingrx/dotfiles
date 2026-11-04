# strato

Work laptop, named after Jimmy's Strato XL rocket. Set up like any other host
(same age key, same GitHub identity), plus the `tl` work tooling in this folder.

## Setup

Let the company MDM finish enrolling the laptop, then follow
[docs/new-host-setup.md](../../../docs/new-host-setup.md) with `HOST=strato`.

## After the first switch

1. AWS: `aws configure sso` with profile name `tl` (it is the default via
   `AWS_PROFILE`), then `aws sso login`.
2. Dev box: `ssh tl-devbox` finds the running box by its `owner-email` tag, read
   from the SSO session, so a rebuilt box needs no config change. Add your SSH
   public key to the box once first.
3. Tailscale: sign in with the work account and turn on Tailscale DNS.
4. Open OrbStack once so it links `docker` (see `modules/darwin/orbstack.nix`).
5. Install the `tl` CLIs by hand and sign in.
