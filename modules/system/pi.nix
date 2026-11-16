{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.pi;
in
{
  options.frogix.pi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "pi coding agent, with pi.nix's binary cache wired into the nix daemon";
    };
    cache = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          add pi.nix's cachix substituters and signing keys to nix.settings.
          upstream ships them only as flake nixConfig, which nix ignores
          without --accept-flake-config — declared here the agent builds from
          the cache with no flags on any host that imports frogix
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # pi — earendil-works' terminal coding agent via lukasl-dev/pi.nix
    # (input wired in flake.nix's hostModules). the agent itself is plain
    # passthrough — rules, skills, jail and sops-backed API keys are set as
    # programs.pi.coding-agent.* directly in the host; this module exists so
    # the suite carries the binary cache (below) instead of every host
    # needing --accept-flake-config.
    programs.pi.coding-agent.enable = true;

    # both substituters from pi.nix's nixConfig: its own build results live on
    # pi.cachix.org, and the bun toolchain behind the -bun variant comes
    # through nix-community (bun2nix). extra-* on purpose: frogix.nix's
    # caches knob assigns substituters/trusted-public-keys outright, and the
    # extra variants append instead of clashing with it.
    nix.settings = lib.mkIf cfg.cache.enable {
      extra-substituters = [
        "https://pi.cachix.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}
