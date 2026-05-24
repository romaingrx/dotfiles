# Restore /usr/local/bin/docker etc. (lost when the docker-desktop cask was removed).
{ lib, ... }:
{
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    if [ -d /Applications/OrbStack.app/Contents/MacOS/xbin ]; then
      mkdir -p /usr/local/bin
      for bin in docker docker-compose docker-buildx docker-credential-osxkeychain; do
        src="/Applications/OrbStack.app/Contents/MacOS/xbin/$bin"
        dst="/usr/local/bin/$bin"
        if [ -e "$src" ]; then
          ln -sfn "$src" "$dst"
        fi
      done
    fi
  '';
}
