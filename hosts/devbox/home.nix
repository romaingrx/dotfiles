# Trajectory Labs dev box: devcontainer plus work tooling. No age key here.
{ pkgs, inputs, ... }:
let
  master = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  sre = pkgs.writeShellScriptBin "sre" ''
    exec sudo -iu sre tmux new-session -A -s sre
  '';

  unlockKeyring = pkgs.writeShellScriptBin "unlock-keyring" ''
    set -euo pipefail
    export PATH="${
      pkgs.lib.makeBinPath [
        pkgs.gnome-keyring
        pkgs.libsecret
        pkgs.procps
        pkgs.coreutils
      ]
    }:$PATH"
    read -rsp 'Keyring password: ' pw
    echo
    pkill -x gnome-keyring-daemon || true
    sleep 0.3
    printf '%s' "$pw" | gnome-keyring-daemon --replace --daemonize --components=secrets --unlock >/dev/null
    unset pw
    if printf x | secret-tool store --label=_probe _keyring_probe 1 >/dev/null 2>&1; then
      secret-tool clear _keyring_probe 1 >/dev/null 2>&1
      echo 'keyring unlocked'
    else
      echo 'keyring still locked: wrong password? re-run unlock-keyring' >&2
      exit 1
    fi
  '';
in
{
  imports = [
    ../devcontainer/home.nix
    ../../modules/home/tl.nix
    ../../modules/home/claude-gateway.nix
    ../../modules/home/envoy-listener.nix
    ../../modules/home/programs/tmux-ctrl-a.nix
  ];

  home.packages = [
    master.uv
    master.herdr
    pkgs.mosh # mosh-server for `mosh tl-devbox-ts` from strato
    pkgs.libsecret
    unlockKeyring
    sre
  ];

  # Python tools (keyring library) store credentials in a plain file. gnome-keyring from
  # nixpkgs registers a D-Bus service whose Exec path exists only on NixOS, so a session bus
  # that reads the Nix profile picks a keyring that cannot start, and every lookup fails.
  xdg.configFile."python_keyring/keyringrc.cfg".text = ''
    [backend]
    default-keyring=keyrings.alt.file.PlaintextKeyring
  '';

  programs.git.settings.user.name = "Romain Graux";
}
