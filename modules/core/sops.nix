{ homeDirectory, ... }:
{
  # sops = {
  #   defaultSopsFile = ../../secrets/default.yaml;
  #   age = {
  #     keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
  #     # Also set the environment variable for the sops command
  #     sshKeyPaths = [ ];
  #   };
  # };
}
