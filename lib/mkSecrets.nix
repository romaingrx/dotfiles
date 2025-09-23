# Secrets management helper function
# Provides clean abstractions for sops-nix with templates and type-safe configuration
{ lib, ... }:

{
# User identification
username, homeDirectory,

# Secrets configuration
secrets ? { },

# Template configuration
templates ? { },

# Global sops settings
globalSopsFile ? null, ageKeyFile ? null, }:

let
  # Default age key file location
  defaultAgeKeyFile = "${homeDirectory}/.config/sops/age/keys.txt";

  # Default sops file location
  defaultSopsFile = ../users + "/${username}/secrets/secrets.yaml";

  # Generate secret configuration with intelligent defaults
  mkSecret = name: config:
    let
      finalSopsFile = config.sopsFile or globalSopsFile;
      secretConfig = {
        sopsFile = finalSopsFile;
      } // (lib.optionalAttrs (config ? path) { path = config.path; })
        // (lib.optionalAttrs (config ? owner) { owner = config.owner; })
        // (lib.optionalAttrs (config ? mode) { mode = config.mode; });
    in lib.nameValuePair name secretConfig;

  # Generate template configuration
  mkTemplate = name: config:
    lib.nameValuePair name {
      content = config.content;
      owner = config.owner or username;
      mode = config.mode or "0644";
    };

in {
  sops = {
    # Age configuration
    age.keyFile = ageKeyFile;

    # Default sops file
    defaultSopsFile = globalSopsFile;

    # Generated secrets
    secrets = lib.listToAttrs (lib.mapAttrsToList mkSecret secrets);

    # Generated templates
    templates = lib.listToAttrs (lib.mapAttrsToList mkTemplate templates);
  };
}
