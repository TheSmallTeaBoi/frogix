{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # ...

    # support both 32- and 64-bit applications
    wineWow64Packages.stable

    # support 32-bit only
    wine

    # support 64-bit only
    (wine.override { wineBuild = "wine64"; })

    # support 64-bit only
    wine64

    # wine-staging (version with experimental features)
    wineWow64Packages.staging

    # winetricks (all versions)
    winetricks

    # native wayland support (unstable)
    wineWow64Packages.waylandFull
  ];
}
