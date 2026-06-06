{ lib }:
let
  inherit (builtins) toJSON;

  span = color: text: "<span color='${color}'><b>${text}</b></span>";

  mkConfig =
    { configPath, theme }:
    let
      f = theme.format;
      calendar = {
        months = span (f.hex theme.palette.rosewater) "{}";
        weekdays = span (f.hex theme.roles.status.warning) "{}";
        today = span (f.hex theme.roles.status.danger) "{}";
      };
    in
    {
      include = [ configPath ];

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
    };

  renderConfig = args: (toJSON (mkConfig args)) + "\n";

  renderThemeCss =
    theme:
    let
      f = theme.format;
      t = theme.roles.ui;
    in
    ''
      @define-color theme_bg ${f.hex t.background};
      @define-color theme_fg ${f.hex t.foreground};
      @define-color theme_muted ${f.hex t.foregroundMuted};
      @define-color theme_accent ${f.hex t.accent};
      @define-color theme_warning ${f.hex theme.roles.status.warning};
      @define-color theme_danger ${f.hex theme.roles.status.danger};
    '';
in
{
  config = renderConfig;
  themeCss = theme: lib.trim (renderThemeCss theme) + "\n";
}
