{ ... }:
{
  nix.settings = {
    substituters = [ "https://romaingrx-dotfiles.cachix.org" ];
    trusted-public-keys = [
      "romaingrx-dotfiles.cachix.org-1:8fwAzNpph5XT2vgLrEFXBKYxUPeaWdfeaGu5AUNkQDc="
    ];
  };
}
