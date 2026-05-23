_final: prev: {
  openssh = prev.openssh.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./openssh.patch ];
    doCheck = false;
  });

  vimPlugins = prev.vimPlugins // {
    fzf-lua = prev.vimPlugins.fzf-lua.overrideAttrs (_old: {
      doCheck = false;
    });
  };

  xdg-desktop-portal = prev.xdg-desktop-portal.overrideAttrs (_old: {
    doCheck = false;
  });
}
