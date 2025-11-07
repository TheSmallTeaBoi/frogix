{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    age = {
      keyFile = "/home/theo/.config/sops/age/keys.txt";
      generateKey = true;
    };
    secrets = {
      navidrome_env = {
        owner = config.services.navidrome.user;
      };
    };
  };
}
