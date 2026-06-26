# File watcher service generator (Linux / systemd).
# Creates a user service that watches files and restarts another service.
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

  description ? "${serviceName} file watcher",
}:

let
  watchEventsStr = lib.concatStringsSep "," watchEvents;
  watchFlags = if recursive then "-r" else "";
  watchPathsStr = lib.concatStringsSep " " (map (path: lib.escapeShellArg path) watchPaths);

  # Generate the watcher script
  watcherScript = pkgs.writeScript "file-watcher-${name}" ''
    #!${pkgs.bash}/bin/bash
    # File watcher daemon for ${serviceName}

    restart_service() {
        echo "Config changed, restarting ${serviceName}..."
        ${restartCommand}
    }

    cleanup() {
        echo "Stopping file watcher for ${serviceName}..."
        exit 0
    }

    trap cleanup SIGTERM SIGINT

    echo "Starting file watcher for ${serviceName}..."
    echo "Watching: ${lib.concatStringsSep " " watchPaths}"

    # Watch for changes and restart the service
    while ${pkgs.inotify-tools}/bin/inotifywait ${watchFlags} -e ${watchEventsStr} ${watchPathsStr}; do
        # Debounce multiple rapid changes
        sleep 0.${toString debounceMs}
        restart_service
    done
  '';
in
lib.mkIf pkgs.stdenv.isLinux {
  systemd.user.services."${name}-watcher" = {
    Unit = {
      Description = description;
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${watcherScript}";
      Restart = "always";
      RestartSec = 3;
      Environment = [
        "PATH=${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${config.home.username}/bin"
      ];
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
