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
    default = true;
    description = "enable the NixOS firewall (defaults on; hosts that need open ports can disable it or open specific ports)";
  };
  options.frogix.networkd.interfaces = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "interfaces dhcpcd is allowed to manage (empty = all non-wireless interfaces; iwd manages wireless DHCP)";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.enable = cfg.firewall;
    networking.dhcpcd = {
      enable = true;
      wait = "background";
      allowInterfaces = lib.mkIf (cfg.interfaces != [ ]) cfg.interfaces;
      # iwd runs its own DHCP client on Wi-Fi (EnableNetworkConfiguration = true),
      # so keep dhcpcd off wireless interfaces when no explicit allowlist is set.
      denyInterfaces = lib.mkIf (cfg.interfaces == [ ]) [
        "wlan*"
        "wlp*"
      ];
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
