{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.plover-flake.homeManagerModules.plover
  ];

  programs.plover = {
    enable = true;
    package = inputs.plover-flake.packages.${pkgs.stdenv.hostPlaform.system}.plover.withPlugins (
      ps: with ps; [
        plover-lapwing-aio
        plover-retro-untranslator
        plover-uinput
        plover-tapey-tape
      ]
    );
  };
}
