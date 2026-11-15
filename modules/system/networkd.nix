{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.networkd;
in
{
  options.frogix.networkd.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "dhcpcd + iwd network stack";
  };
  options.frogix.networkd.firewall = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "keep the firewall disabled (the frogix default)";
  };
  options.frogix.networkd.interfaces = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "interfaces dhcpcd is allowed to manage (empty = all)";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.enable = cfg.firewall;
    networking.dhcpcd = {
      enable = true;
      wait = "background";
      allowInterfaces = lib.mkIf (cfg.interfaces != [ ]) cfg.interfaces;
    };

    networking.wireless.iwd = {
      enable = true;
      settings = {
        General = {
          EnableNetworkConfiguration = true;
        };
      };
    };
  };
}
