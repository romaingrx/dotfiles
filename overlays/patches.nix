# Patches and modifications overlay
# This overlay applies patches and modifications to existing packages
final: prev: {
  # OpenSSH with patches
  openssh = prev.openssh.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./openssh.patch ];
    doCheck = false;
  });
}
