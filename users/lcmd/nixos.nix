{ ... }:
{
  users.users.romaingrx = {
    isNormalUser = true;
    home = "/home/lcmd";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    createHome = true;
    name = "lcmd";
  };
}
