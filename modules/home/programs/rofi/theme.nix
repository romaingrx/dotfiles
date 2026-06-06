{ lib }:
let
  renderConfig =
    theme:
    let
      f = theme.format;
      t = theme.roles.ui;
    in
    ''
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
        border-color: ${f.hex t.border};
        border-radius: 10px;
        background-color: ${f.hex t.background};
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
        background-color: ${f.hex t.accent};
        padding: 6px;
        text-color: ${f.hex t.background};
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
        text-color: ${f.hex t.accent};
        background-color: ${f.hex t.background};
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
        text-color: ${f.hex t.accent};
      }

      element-icon {
        size: 25px;
      }

      element selected {
        text-color: ${f.hex t.background};
        background-color: ${f.hex t.accent};
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
in
{
  config = theme: lib.trim (renderConfig theme) + "\n";
}
