{ lib, identity, ... }:
let
  personal = identity == "personal";
in
{
  imports = [
    ../../modules/home
    ../../modules/nvim.nix
    ./home-manager-nixos.nix
    ./home-manager-darwin.nix
    ./rust.nix
  ]
  # Personal keys (sops age key -> GPG + GitHub SSH keys) never land on a work host.
  ++ lib.optionals personal [
    ./secrets.nix
    ./gpg.nix
  ];

  programs.git = lib.mkMerge [
    { settings.user.name = "Romain Graux"; }

    (lib.mkIf personal {
      signing = {
        key = "383E2222E1BEFDAD";
        signByDefault = true;
      };
      settings = {
        user.email = "48758915+romaingrx@users.noreply.github.com";
        commit.gpgsign = true;
      };
    })

    # Work host: sign with the machine's own SSH key (generated on the laptop and
    # added to GitHub as a signing key) instead of the personal GPG key. The work
    # email is kept out of this repo, in a local ~/.config/git/work.gitconfig.
    (lib.mkIf (!personal) {
      settings = {
        include.path = "~/.config/git/work.gitconfig";
        user.signingkey = "~/.ssh/id_ed25519.pub";
        gpg.format = "ssh";
        commit.gpgsign = true;
        tag.gpgsign = true;
      };
    })
  ];
}
