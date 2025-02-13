{ }:
{ pkgs, ... }: {
  imports = [ ../../modules/core/common ];

  # State version
  home.packages = with pkgs; [ openbabel zoom-us ];
}
