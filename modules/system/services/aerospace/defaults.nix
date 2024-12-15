{ pkgs, ... }: {
  enable = true;
  package = pkgs.aerospace;
  settings = pkgs.lib.importTOML ./aerospace.toml;

  # settings = {
  #   accordion-padding = 30;
  #   gaps = {
  #     inner.horizontal = 8;
  #     inner.vertical = 8;
  #     outer.left = 8;
  #     outer.bottom = 8;
  #     outer.top = 8;
  #     outer.right = 8;
  #   };
  #   mode = {
  #     main = {
  #       binding = {
  #         alt-shift-semicolon = "mode service";

  #         # Workspace settings
  #         alt-1 = "workspace 1";
  #         alt-2 = "workspace 2";
  #         alt-3 = "workspace 3";
  #         alt-b = "workspace B"; # Browser

  #         alt-shift-1 = "move-node-to-workspace 1";
  #         alt-shift-2 = "move-node-to-workspace 2";
  #         alt-shift-3 = "move-node-to-workspace 3";

  #         alt-h = "focus left";
  #         alt-j = "focus down";
  #         alt-k = "focus up";
  #         alt-l = "focus right";

  #         alt-shift-h = "move left";
  #         alt-shift-j = "move down";
  #         alt-shift-k = "move up";
  #         alt-shift-l = "move right";

  #         alt-f = "fullscreen";
  #         alt-t = "layout vertical";
  #         alt-m = "layout tiling";

  #         alt-shift-minus = "resize smart -50";
  #         alt-shift-equal = "resize smart 50";

  #         alt-slash = "layout tiles horizontal vertical";
  #         alt-comma = "layout accordion horizontal vertical";


  #       };
  #     };
  #     service = {
  #       binding = {
  #         # Will be used to manage the windows
  #         alt-shift-semicolon = "mode main";

  #       };
  #     };
  #   };
  #   on-window-detected = [
  #     "{ if app-id = 'com.apple.finder'; run = 'move-node-to-workspace 3';}"
  #   ];
  # };
}
