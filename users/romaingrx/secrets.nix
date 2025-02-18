{ ... }:
let
  gpg_sops_file = ./secrets/gpg.yaml;
  ssh_sops_file = ./secrets/ssh.yaml;
  homedir = "/Users/romaingrx";
in {
  sops = {
    age = { keyFile = "${homedir}/.config/sops/age/keys.txt"; };
    secrets = {
      "gpg_github_private_key" = {
        path = "${homedir}/Desktop/github_private_key";
        sopsFile = gpg_sops_file;
      };

      "ssh_github_private_key" = {
        path = "${homedir}/.ssh/github";
        sopsFile = ssh_sops_file;
      };
    };
  };
}
