{ pkgs, inputs, ... }: {
  imports = [
    ../../modules/common
    ./secrets.nix
    ./gpg.nix
    ./home-manager-nixos.nix
    ./rust.nix
  ];

  # Enable the new configuration options
  myConfig = {
    common.enable = true;

    # User packages (Home Manager)
    packages = {
      enable = true;
      core.enable = true;
      development.enable = true;
      productivity.enable = true;
      extraPackages = with pkgs; [
        inputs.romaingrx-nixvim.packages.${system}.default
        ollama
        tor
        mitmproxy
        brave
        tailscale
        claude-code
      ];
    };

    programs.enable = true;

    # System packages (environment.systemPackages)
    systemPackages = {
      enable = true;
      core.enable = true;
      development.enable = true;
    };

    # External packages (Homebrew on Darwin) - temporarily disabled
    # Will be configured at system level in future phase
    # externalPackages = {
    #   enable = true;
    #   homebrew = {
    #     enable = true;
    #     browsers.enable = true;
    #     productivity.enable = true;
    #     development.enable = true;
    #     media.enable = true;
    #   };
    # };
  };

  # Compatibility configuration for original git.nix
  home.github.gpg = {
    key = "EE706544613BE505";
    email = "48758915+romaingrx@users.noreply.github.com";
  };
}
