{ config, ... }:
let
  gpg_sops_file = ./secrets/gpg.yaml;
  ssh_sops_file = ./secrets/ssh.yaml;
  homeDirectory = config.home.homeDirectory;
in {
  sops = {
    age = { keyFile = "${homeDirectory}/.config/sops/age/keys.txt"; };
    secrets = {
      "gpg_github_private_key" = {
        path = "${homeDirectory}/Desktop/github_private_key";
        sopsFile = gpg_sops_file;
      };

      "ssh_github_private_key" = {
        path = "${homeDirectory}/.ssh/github";
        sopsFile = ssh_sops_file;
      };
    };
  };
}
