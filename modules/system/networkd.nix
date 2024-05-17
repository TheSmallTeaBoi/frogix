{
  inputs,
  outputs,
  config,
  pkgs,
  ...
}: {
  networking.dhcpcd = {
    enable = true;
    wait = "background";
  };
}
