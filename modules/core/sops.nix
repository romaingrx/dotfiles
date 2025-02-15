{ homeDirectory, ... }: {
  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      sshKeyPaths = [ "${homeDirectory}/.ssh/id_host" ];
      keyFile = "${homeDirectory}/.config/sops/age/key.txt";
      generateKey = true;
    };
    secrets = { test = { }; };
  };
}
