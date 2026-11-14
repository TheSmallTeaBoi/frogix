{
  inputs,
  outputs,
  config,
  pkgs,
  ...
}:
{
  networking.dhcpcd = {
    enable = true;
    wait = "background";
    allowInterfaces = [ "enp38s0" ];
  };

  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = true;
      };
    };
  };
}
