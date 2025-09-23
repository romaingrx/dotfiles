# File watcher service generator
# Creates a daemon that watches for file changes and restarts a service
#
# Usage example:
# (mkFileWatcher {
#   name = "waybar";
#   serviceName = "waybar";
#   restartCommand = "pkill waybar; sleep 0.2; waybar &";
#   watchPaths = [ "/path/to/config/dir/" ];
#   description = "Waybar with auto-restart on config changes";
# })
{
  lib,
  config,
  pkgs,
  ...
}:

{
  # Service identification
  name,

  # Service to restart when files change
  serviceName,
  restartCommand,

  # Files/directories to watch
  watchPaths,
  watchEvents ? [
    "create"
    "modify"
    "delete"
    "moved_to"
  ],

  # Watch configuration
  recursive ? true,
  debounceMs ? 500,
  initialLaunch ? false,

  # Service configuration
  description ? "${serviceName} file watcher",
  enabled ? true,
  wantedBy ? [ "graphical-session.target" ],
  after ? [ "graphical-session.target" ],
  requires ? [ ],

  # Environment
  environment ? { },
}:

let
  watchEventsStr = lib.concatStringsSep "," watchEvents;
  watchFlags = if recursive then "-r" else "";
  watchPathsStr = lib.concatStringsSep " " (map (path: lib.escapeShellArg path) watchPaths);

  # Generate the watcher script
  watcherScript = pkgs.writeScript "file-watcher-${name}" ''
    #!${pkgs.bash}/bin/bash
    # File watcher daemon for ${serviceName}

    # Function to restart the service
    restart_service() {
        echo "Config changed, restarting ${serviceName}..."
        ${restartCommand}
    }

    # Function to cleanup on exit
    cleanup() {
        echo "Stopping file watcher for ${serviceName}..."
        exit 0
    }

    # Trap signals for cleanup
    trap cleanup SIGTERM SIGINT

    # Wait for service to start
    ${
      if initialLaunch then
        ''
          echo "${serviceName} not running, starting it..."
          ${restartCommand}
        ''
      else
        ""
    }

    echo "Starting file watcher for ${serviceName}..."
    echo "Watching: ${lib.concatStringsSep " " watchPaths}"

    # Watch for changes and restart service
    while ${pkgs.inotify-tools}/bin/inotifywait ${watchFlags} -e ${watchEventsStr} ${watchPathsStr}; do
        # Debounce multiple rapid changes
        sleep 0.${toString debounceMs}
        restart_service
    done
  '';

in
lib.mkMerge [
  # Linux (systemd) configuration
  (lib.mkIf pkgs.stdenv.isLinux {
    systemd.user.services."${name}-watcher" = {
      Unit = {
        Description = description;
        After = after;
        Requires = requires;
      };

      Service = {
        Type = "simple";
        ExecStart = "${watcherScript}";
        Restart = "always";
        RestartSec = 3;
        Environment = lib.mapAttrsToList (name: value: "${name}=${toString value}") (
          environment
          // {
            PATH = "${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${config.home.username}/bin";
          }
        );
      };

      Install = lib.mkIf enabled { WantedBy = wantedBy; };
    };
  })

  # Darwin (launchd) configuration - would need fswatch instead of inotify-tools
  (lib.mkIf pkgs.stdenv.isDarwin {
    # TODO: Implement Darwin version using fswatch
    # For now, this is Linux-only
  })
]
