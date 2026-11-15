{
  inputs,
  outputs,
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
    inputs.home-manager.nixosModules.home-manager
  ];

  config = lib.mkIf cfg.enable {
    home-manager.backupFileExtension = "back";

    home-manager = {
      extraSpecialArgs = { inherit inputs outputs; };
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
