final: prev: {
  claude-code = 
    if prev ? claude-code then
      throw ''
        claude-code is now available in nixpkgs!
        The PR has been merged: https://github.com/NixOS/nixpkgs/pull/384860
      ''
    else
      final.callPackage ./claude-code {};
} 