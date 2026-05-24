# Bridge OrbStack's docker CLI into /usr/local/bin so callers that hardcode
# that path (historically populated by docker-desktop) keep working.
# No-op on machines without OrbStack installed.
_: {
  system.activationScripts.orbstackCli.text = ''
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
