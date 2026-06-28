{
  config,
  lib,
  pkgs,
  ...
}:
let
  gpg_sops_file = ./secrets/gpg.yaml;
  ssh_sops_file = ./secrets/ssh.yaml;
  inherit (config.home) homeDirectory;
in
{
  sops = {
    age = {
      keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
    };

    secrets = {
      "gpg_github_private_key" = {
        path = "${homeDirectory}/.config/gnupg/private.key";
        sopsFile = gpg_sops_file;
        mode = "0600";
      };
    }
    # The GitHub SSH key, decrypted to where ssh.nix expects it. Inert until
    # secrets/ssh.yaml exists — add it with: sops users/romaingrx/secrets/ssh.yaml
    // lib.optionalAttrs (builtins.pathExists ssh_sops_file) {
      "github_ssh_private_key" = {
        path = "${homeDirectory}/.ssh/github";
        sopsFile = ssh_sops_file;
        mode = "0600";
      };
    };
  };

  # Updated activation script for GPG key import
  home.activation = {
    importGpgKey =
      let
        gpg = "${pkgs.gnupg}/bin/gpg";
        # Add tty requirement for GPG
        exportGPGTTY = "export GPG_TTY=$(tty)";
      in
      ''
        # Ensure proper GPG environment
        ${exportGPGTTY}
        if [ -f "${config.sops.secrets.gpg_github_private_key.path}" ]; then
          # Check if the key is already imported
          if ! ${gpg} --list-secret-keys | grep -q "${config.programs.git.signing.key}"; then
            echo "Importing GPG key..."
            # Add --batch mode to avoid pinentry issues
            $DRY_RUN_CMD ${gpg} --batch --import "${config.sops.secrets.gpg_github_private_key.path}"
          else
            echo "GPG key already imported, skipping..."
          fi
        fi
      '';
  };
}
