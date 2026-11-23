{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.frogix;
in
{
  imports = [
    ./system
  ];

  config = lib.mkIf cfg.enable {
    home-manager.backupFileExtension = "back";

    home-manager = {
      extraSpecialArgs = { inherit inputs; };
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${cfg.user} = {
        imports = [ ./home-manager ];
        frogix.enable = lib.mkDefault cfg.enable;
        frogix.user = lib.mkDefault cfg.user;
      };
    };
  };
}
