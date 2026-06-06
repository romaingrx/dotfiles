{ lib }:
let
  inherit (builtins) toJSON;

  span = color: text: "<span color='${color}'><b>${text}</b></span>";

  mkConfig =
    theme:
    let
      f = theme.format;
      calendar = {
        months = span (f.hex theme.palette.rosewater) "{}";
        weekdays = span (f.hex theme.roles.status.warning) "{}";
        today = span (f.hex theme.roles.status.danger) "{}";
      };
    in
    {
      reload_style_on_change = true;
      layer = "top";
      position = "top";
      spacing = 0;
      height = 26;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [
        "network"
        "memory"
        "cpu"
      ];

      "hyprland/workspaces" = {
        on-click = "activate";
        format = "{icon}";
        format-icons = {
          default = "";
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";
          active = "󱓻";
        };
        persistent-workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
        };
      };

      cpu = {
        interval = 1;
        format = "{icon0}{icon1}{icon2}{icon3} {usage:>2}% ";
        format-icons = [
          "▁"
          "▂"
          "▃"
          "▄"
          "▅"
          "▆"
          "▇"
          "█"
        ];
      };

      clock = {
        interval = 1;
        format = "{:L%H:%M:%S}";
        format-alt = "{:L%d %B W%V %Y}";
        tooltip = true;
        tooltip-format = "<tt>{calendar}</tt>";
        calendar = {
          mode = "month";
          mode-mon-col = 3;
          on-scroll = 1;
          on-click-right = "mode";
          format = calendar;
        };
      };

      network = {
        interface = "ens18";
        format = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
        format-ethernet = "<span>⇣{bandwidthDownBytes}</span> <span>⇡{bandwidthUpBytes}</span> 󰀂";
        format-disconnected = "󰤮";
        tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
        tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
        tooltip-format-disconnected = "Disconnected";
        interval = 3;
        spacing = 1;
      };

      bluetooth = {
        format = "";
        format-disabled = "󰂲";
        format-connected = "";
        tooltip-format = "Devices connected: {num_connections}";
        on-click = "$TERMINAL -e bluetoothctl";
      };

      pulseaudio = {
        format = "{icon}";
        on-click = "$TERMINAL --class=Wiremix -e wiremix";
        on-click-right = "pamixer -t";
        tooltip-format = "Playing at {volume}%";
        scroll-step = 5;
        format-muted = "";
        format-icons.default = [
          ""
          ""
          ""
        ];
      };

      memory = {
        interval = 30;
        format = "{used:0.1f}G/{total:0.1f}G ";
      };

      "custom/gpu" = {
        format = "{} {icon}";
        exec = "gpu-usage-waybar";
        return-type = "json";
        format-icons = "󰾲";
        on-click = "$TERMINAL -e nvtop";
      };
    };

  renderConfig = theme: (toJSON (mkConfig theme)) + "\n";

  renderStyle =
    theme:
    let
      f = theme.format;
      t = theme.roles.ui;
    in
    ''
      * {
        background-color: ${f.hex t.background};
        color: ${f.hex t.foreground};

        border: none;
        border-radius: 0;
        min-height: 0;
        font-family: "FiraCode Nerd Font";
        font-size: 12px;
      }

      .modules-left {
        margin-left: 8px;
      }

      .modules-right {
        margin-right: 8px;
      }

      #workspaces button {
        all: initial;
        padding: 0 6px;
        margin: 0 1.5px;
        min-width: 9px;
      }

      #workspaces button.empty {
        opacity: 0.5;
      }

      #tray,
      #cpu,
      #battery,
      #network,
      #bluetooth,
      #pulseaudio {
        min-width: 12px;
        margin: 0 7.5px;
      }

      tooltip {
        padding: 2px;
      }

      #clock {
        margin-left: 8.75px;
      }

      .hidden {
        opacity: 0;
      }
    '';
in
{
  config = renderConfig;
  style = theme: lib.trim (renderStyle theme) + "\n";
}
