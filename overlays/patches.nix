# Patches and modifications overlay
# This overlay applies patches and modifications to existing packages
final: prev: {
  # OpenSSH with patches
  openssh = prev.openssh.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./openssh.patch ];
    doCheck = false;
  });

  # Disable tests for fzf-lua vim plugin to avoid GUI test failures in Nix build
  vimPlugins = prev.vimPlugins // {
    fzf-lua = prev.vimPlugins.fzf-lua.overrideAttrs (old: {
      doCheck = false;
    });
  };
}
