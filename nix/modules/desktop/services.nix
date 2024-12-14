{pkgs, ...}: {
  services = {
    spacebar = {
      enable = true;
      package = pkgs.spacebar;
      config = {
        clock_format = "%R";
      };
    };
  };
} 