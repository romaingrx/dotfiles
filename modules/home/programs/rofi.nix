{ lib, pkgs, ... }:
let
  inherit (import ../../../lib/theme) palette;
  background = "#${palette.base}";
  accent = "#${palette.mauve}";
in
{
  xdg.configFile."rofi/config.rasi" = lib.mkIf pkgs.stdenv.isLinux {
    # Replaces the symlink left by the old runtime theme switcher.
    force = true;
    text = ''
      configuration {
        modi: "drun,run,window";
        show-icons: true;
        terminal: "alacritty";
        drun-display-format: "{icon} {name}";
        location: 0;
        disable-history: false;
        hide-scrollbar: true;
        display-drun: "   Apps ";
        display-run: "   Run ";
        display-window: " 﩯  Window";
        display-Network: " 󰤨  Network";
        sidebar-mode: true;
      }

      window {
        width: 1000px;
        border: 2px;
        border-color: ${accent};
        border-radius: 10px;
        background-color: ${background};
      }

      mainbox {
        background-color: transparent;
      }

      inputbar {
        children: [prompt,entry];
        background-color: transparent;
        border-radius: 5px;
        padding: 2px;
      }

      prompt {
        background-color: ${accent};
        padding: 6px;
        text-color: ${background};
        border-radius: 8px;
        margin: 20px 0px 0px 20px;
      }

      textbox-prompt-colon {
        expand: false;
        str: ":";
      }

      entry {
        padding: 6px;
        margin: 20px 0px 0px 10px;
        text-color: ${accent};
        background-color: ${background};
      }

      listview {
        border: 0px 0px 0px;
        padding: 6px 0px 0px;
        margin: 10px 0px 0px 20px;
        columns: 2;
        background-color: transparent;
      }

      element {
        padding: 5px;
        background-color: transparent;
        text-color: ${accent};
      }

      element-icon {
        size: 25px;
      }

      element selected {
        text-color: ${background};
        background-color: ${accent};
        border-radius: 8px;
      }

      element-text {
        background-color: transparent;
        text-color: inherit;
        vertical-align: 0.5;
      }

      element-text selected {
        background-color: transparent;
      }
    '';
  };
}
