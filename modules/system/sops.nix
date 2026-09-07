{ config, ... }:
{
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
      hermes_env = {
        owner = "theo";
      };
      hermes_dashboard_token = {
        owner = config.services.hermes-agent.user;
      };
    };
  };
}
