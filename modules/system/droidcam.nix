{
  inputs,
  pkgs,
  ...
}:
{
  programs = {
    droidcam = {
      enable = true;
    };
    dconf = {
      enable = true;
    };
  };
}
