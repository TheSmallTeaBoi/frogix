{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.nix;
in
{
  options.frogix.nix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "nix daemon settings, caches and nix tooling defaults (also sets nixpkgs.config.allowUnfree)";
    };
    gc = {
      automatic = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "run nix-collect-garbage on a schedule";
      };
      dates = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "systemd calendar for the gc timer";
      };
      options = lib.mkOption {
        type = lib.types.str;
        default = "--delete-older-than 3d";
        description = "extra flags passed to nix-collect-garbage";
      };
    };
    optimise = {
      automatic = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "run nix-store --optimise on a schedule";
      };
      dates = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "weekly" ];
        description = "systemd calendar for the optimise timer";
      };
    };
    experimentalFeatures = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "nix-command"
        "flakes"
      ];
      description = "nix experimental-features to enable";
    };
    trustedUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "root"
        "@wheel"
      ];
      description = "nix trusted-users";
    };
    caches = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "extra binary caches: substituter url -> signing key";
    };
    permittedInsecurePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "nixpkgs.config.permittedInsecurePackages";
    };
    documentation = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable the NixOS documentation (slows generations down)";
    };
    ld.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "programs.nix-ld for prebuilt binaries";
    };
    comma.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "comma on top of the nix-index database";
    };
  };

  config = lib.mkIf cfg.enable {
    # use extra-* so cache.nixos.org stays first and extra caches only take misses
    nix.settings.extra-substituters = builtins.attrNames cfg.caches;
    nix.settings.extra-trusted-public-keys = builtins.attrValues cfg.caches;

    nix = {
      gc = {
        automatic = cfg.gc.automatic;
        dates = cfg.gc.dates;
        options = cfg.gc.options;
      };
      optimise = {
        automatic = cfg.optimise.automatic;
        dates = cfg.optimise.dates;
      };
      settings = {
        experimental-features = cfg.experimentalFeatures;
        trusted-users = cfg.trustedUsers;
        fallback = true;
        connect-timeout = 5;
        http-connections = 50;
        max-substitution-jobs = 32;
        # auto-GC when free space drops below 10 GiB until 30 GiB is free
        min-free = 10 * 1024 * 1024 * 1024;
        max-free = 30 * 1024 * 1024 * 1024;
      };
    };

    nixpkgs.config = {
      allowUnfree = true;
      permittedInsecurePackages = cfg.permittedInsecurePackages;
    };

    documentation.enable = cfg.documentation;

    programs.nix-ld.enable = cfg.ld.enable;

    programs.nix-index-database.comma.enable = cfg.comma.enable;
  };
}
