# Custom packages overlay
# Add custom package definitions here
final: prev: {
  # Custom packages can be defined here
  # Example:
  # myCustomPackage = final.callPackage ./packages/my-custom-package { };

  # Pin Claude Code to version 2.0.62
  # Commented out - using nixpkgs version instead
  # claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
  #   version = "2.0.62";
  #   src = prev.fetchurl {
  #     url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
  #     hash = "";
  #   };
  #   npmDepsHash = "";
  # });
}
