{ config, pkgs, ... }:
let
  gpg_sops_file = ./secrets/gpg.yaml;
  ssh_sops_file = ./secrets/ssh.yaml;
  homeDirectory = config.home.homeDirectory;
in {
  sops = {
    age = { keyFile = "${homeDirectory}/.config/sops/age/keys.txt"; };
    secrets = {
      "gpg_github_private_key" = {
        path = "${homeDirectory}/.config/gnupg/private.key";
        sopsFile = gpg_sops_file;
        mode = "0600";
      };

      "ssh_github_private_key" = {
        path = "${homeDirectory}/.ssh/github";
        sopsFile = ssh_sops_file;
      };
    };
  };

  # Add an activation script to import the GPG key
  home.activation = {
    importGpgKey = let
      gpg = "${pkgs.gnupg}/bin/gpg";
    in ''
      if [ -f "${config.sops.secrets.gpg_github_private_key.path}" ]; then
        $DRY_RUN_CMD ${gpg} --import "${config.sops.secrets.gpg_github_private_key.path}"
      fi
    '';
  };
}
