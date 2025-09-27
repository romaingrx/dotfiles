{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.mitmproxy;

  # Create a derivation for the certificate installation script
  certInstallScript = pkgs.writeShellScriptBin "install-mitmproxy-cert" ''
    #!/usr/bin/env bash
    set -e

    CERT_DIR="$HOME/.mitmproxy"
    mkdir -p "$CERT_DIR"

    # Generate certificates if they don't exist
    if [ ! -f "$CERT_DIR/mitmproxy-ca-cert.pem" ]; then
      echo "Generating new mitmproxy certificates..."
      ${pkgs.mitmproxy}/bin/mitmdump --set confdir="$CERT_DIR" &
      MITM_PID=$!
      sleep 2
      kill $MITM_PID
      sleep 1  # Wait for process to fully terminate
    fi

    # Convert PEM to CER format for macOS
    ${pkgs.openssl}/bin/openssl x509 -outform der -in "$CERT_DIR/mitmproxy-ca-cert.pem" -out "$CERT_DIR/mitmproxy-ca-cert.cer"

    # Install certificate to System Keychain if not already installed
    if ! security find-certificate -c "mitmproxy" /Library/Keychains/System.keychain >/dev/null 2>&1; then
      echo "Installing certificate to System Keychain..."
      sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" "$CERT_DIR/mitmproxy-ca-cert.cer"
    else
      echo "Certificate already installed."
    fi

    echo "Certificate setup complete."
  '';

  # Create a derivation for the toggle-proxy script
  toggleProxyScript = pkgs.writeShellScriptBin "toggle-proxy" (
    builtins.readFile ./bin/toggle-proxy.sh
  );
in
{
  options.services.mitmproxy = {
    enable = mkEnableOption "Enable proxy service";

    port = mkOption {
      type = types.int;
      default = 8080;
      description = "Port for the proxy server";
    };

    upstreamProxy = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Upstream proxy URL (e.g., http://proxy.example.com:8080)";
    };

    autoConfig = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to automatically configure system proxy settings";
    };

    interfaces = mkOption {
      type = types.listOf types.str;
      default = [ "Wi-Fi" ];
      description = "Network interfaces to configure proxy for";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra arguments to pass to mitmproxy";
    };
  };

  config = mkIf cfg.enable {
    # Add mitmproxy to system packages
    environment.systemPackages = with pkgs; [
      mitmproxy
      certInstallScript
      toggleProxyScript
    ];

    # Create launchd service for mitmproxy
    launchd.user.agents.mitmproxy = {
      serviceConfig = {
        Label = "com.user.mitmproxy";
        ProgramArguments =
          let
            args = [
              "${pkgs.mitmproxy}/bin/mitmproxy"
              "--listen-port"
              (toString cfg.port)
              "--set"
              "confdir=$HOME/.mitmproxy"
              "--mode"
              "regular"
              "--showhost"
            ]
            ++ (optionals (cfg.upstreamProxy != null) [
              "--mode"
              "upstream:${cfg.upstreamProxy}"
            ])
            ++ cfg.extraArgs;
          in
          args;
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/mitmproxy.log";
        StandardErrorPath = "/tmp/mitmproxy.error.log";
      };
    };

    # Configure system proxy settings if autoConfig is enabled
    system.activationScripts.extraActivation.text = mkIf cfg.autoConfig ''
      # Display a message about certificate installation
      echo "Please run 'install-mitmproxy-cert' once to set up the proxy certificates"
      echo "You can use 'toggle-proxy on|off|status' to manage proxy settings"

      # Configure network proxy settings
      ${optionalString cfg.autoConfig (
        concatStringsSep "\n" (
          map (interface: ''
            echo "Configuring proxy settings for ${interface}..."
            networksetup -setwebproxy "${interface}" "127.0.0.1" ${toString cfg.port}
            networksetup -setsecurewebproxy "${interface}" "127.0.0.1" ${toString cfg.port}
          '') cfg.interfaces
        )
      )}
    '';
  };
}
