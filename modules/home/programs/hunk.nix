{ inputs, ... }:
{
  # Home Manager module shipped by the hunk flake input. It provides the
  # flake-built `hunk` package (not in nixpkgs) and manages both the package and
  # its config file at ~/.config/hunk/config.toml.
  imports = [ inputs.hunk.homeManagerModules.default ];

  programs.hunk = {
    enable = true;

    # Set hunk as git's diff pager. This writes
    # `programs.git.settings.core.pager = "hunk pager"`, so `git diff` and
    # `git show` open in the hunk review UI. Requires programs.git.enable, which
    # is set in ./git.nix. Having the `hunk` CLI on PATH is also what lets the
    # pi-hunk Pi plugin attach to / launch live hunk review sessions.
    enableGitIntegration = true;

    settings = {
      # Match the rest of the setup, which themes everything with Catppuccin
      # (dark default). Use "auto" instead to follow the terminal background.
      theme = "catppuccin-mocha";
      mode = "auto"; # auto | split | stack
      line_numbers = true;
    };
  };
}
