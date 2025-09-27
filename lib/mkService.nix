# Cross-platform service abstraction
# Generates systemd services on Linux and launchd agents on Darwin
{ lib, pkgs, ... }:

{
  # Service identification
  name,

  # Service configuration
  description ? "${name} service",
  command,
  args ? [ ],

  # Service behavior
  enabled ? true,
  wantedBy ? [ "default.target" ],
  after ? [ ],
  requires ? [ ],

  # Process configuration
  user ? null,
  group ? null,
  workingDirectory ? null,
  environment ? { },

  # Restart configuration
  restart ? "on-failure",
  restartSec ? "5s",

  # Darwin-specific options
  keepAlive ? true,
  runAtLoad ? true,

  # Linux-specific options
  serviceType ? "simple",

  # Logging
  standardOutput ? null,
  standardError ? null,
}:

let
  # Build full command with arguments
  fullCommand = if args == [ ] then command else "${command} ${lib.escapeShellArgs args}";

  # Environment variables as shell format
  envVars = lib.mapAttrsToList (
    name: value: "${name}=${lib.escapeShellArg (toString value)}"
  ) environment;
  envString = lib.concatStringsSep " " envVars;

in
lib.mkMerge [
  # Darwin (launchd) configuration
  (lib.mkIf pkgs.stdenv.isDarwin {
    launchd.user.agents.${name} = {
      serviceConfig = {
        Label = "org.nixos.${name}";
        ProgramArguments = [
          pkgs.bash
          "-c"
        ]
        ++ lib.optional (envString != "") "export ${envString}; "
        ++ [ fullCommand ];
        KeepAlive = keepAlive;
        RunAtLoad = runAtLoad;
      }
      // lib.optionalAttrs (workingDirectory != null) {
        WorkingDirectory = workingDirectory;
      }
      // lib.optionalAttrs (standardOutput != null) {
        StandardOutPath = standardOutput;
      }
      // lib.optionalAttrs (standardError != null) {
        StandardErrorPath = standardError;
      };
    };
  })

  # Linux (systemd) configuration
  (lib.mkIf pkgs.stdenv.isLinux {
    systemd.user.services.${name} = {
      Unit = {
        Description = description;
        After = after;
        Requires = requires;
      };

      Service = {
        Type = serviceType;
        ExecStart = fullCommand;
        Restart = restart;
        RestartSec = restartSec;
        Environment = lib.mapAttrsToList (name: value: "${name}=${toString value}") environment;
      }
      // lib.optionalAttrs (user != null) { User = user; }
      // lib.optionalAttrs (group != null) { Group = group; }
      // lib.optionalAttrs (workingDirectory != null) {
        WorkingDirectory = workingDirectory;
      }
      // lib.optionalAttrs (standardOutput != null) {
        StandardOutput = standardOutput;
      }
      // lib.optionalAttrs (standardError != null) {
        StandardError = standardError;
      };

      Install = lib.mkIf enabled { WantedBy = wantedBy; };
    };
  })
]
