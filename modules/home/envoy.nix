# claude-envoy plugin, pinned. Install once per user:
#   claude plugin marketplace add ~/.config/claude-envoy-pin
#   claude plugin install claude-envoy@legion-envoy-pinned
{ config, lib, ... }:
{
  options.dotfiles.envoy.machineId = lib.mkOption {
    type = lib.types.str;
    default = "devbox-romain-graux";
    description = "This machine's name on Envoy: its Tailscale host name.";
  };

  config = {
    home.sessionVariables.ENVOY_MACHINE_ID = config.dotfiles.envoy.machineId;

    xdg.configFile."claude-envoy-pin/.claude-plugin/marketplace.json".text = builtins.toJSON {
      name = "legion-envoy-pinned";
      owner.name = "Romain Graux";
      plugins = [
        {
          name = "claude-envoy";
          source = {
            source = "npm";
            package = "@sjawhar/claude-envoy";
            # 2.9.0+ needs a newer listener than envoy-listener.nix runs.
            version = "1.39.1";
          };
        }
      ];
    };
  };
}
