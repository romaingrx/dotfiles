# One Envoy listener per machine, on 127.0.0.1:9020, shared by every user.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.dotfiles.envoy) machineId;
  docker = lib.getExe' pkgs.docker-client "docker";
  # legion-envoy v13.26.0, agent-c's production pin.
  image = "ghcr.io/sjawhar/legion/envoy@sha256:5c9d7eee1e8b1e1362a434c84e9004d2d4432617c4b5a477c7d00075bde162a8";
in
{
  imports = [ ./envoy.nix ];

  systemd.user.services.envoy-listener = {
    Unit.Description = "Envoy listener for ${machineId}";
    Service = {
      ExecStartPre = "-${docker} rm --force envoy-listener";
      ExecStart = lib.escapeShellArgs [
        docker
        "run"
        "--rm"
        "--init"
        "--name=envoy-listener"
        "--network=host"
        "--log-opt=max-size=20m"
        "--log-opt=max-file=3"
        "--env=ENVOY_MACHINE_ID=${machineId}"
        "--env=NATS_URLS=nats://envoy-nats.tailb86685.ts.net:4222"
        "--env=ENVOY_ALLOW_REMOTE_NATS=1"
        image
      ];
      ExecStop = "${docker} stop --time 10 envoy-listener";
      SuccessExitStatus = "143";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
