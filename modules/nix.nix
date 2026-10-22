# Nix daemon settings shared by every host.
_: {
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-jobs = "auto";
      substituters = [ "https://romaingrx-dotfiles.cachix.org" ];
      trusted-public-keys = [
        "romaingrx-dotfiles.cachix.org-1:8fwAzNpph5XT2vgLrEFXBKYxUPeaWdfeaGu5AUNkQDc="
      ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
  };
}
