{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  cfg = config.frogix.hermes;
in
{
  options.frogix."hermes".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "hermes-desktop client with the patched pm-package seam";
  };

  config = lib.mkIf cfg.enable {
    # hermes-desktop — the one Hermes piece this host keeps (Theo, 2026-09-21).
    # No hermes services or CLI live here anymore; the app is a client and gets
    # pointed at the home server. `programs.hermes-agent.enable` (the CLI) and
    # the old `chai` service-home wrapper are deliberately NOT set.
    #
    # 2026-11-06: upstream's desktop.nix now takes electron headers from
    # nixpkgs' own electron.headers derivation (tracks every bump, no stale
    # hash), so the local hermes-electron-headers patch + repackage is gone
    # and the module's default package is used as-is.
    #
    # 2026-11-13: nixpkgs (26.11.20261111) rolled patchelf back to 0.15.2,
    # past the 0.19.2 corruption bug, so hermes-agent's vendored patchelfFixed
    # patch (the #674 fix, written against 0.19.x) no longer applies and
    # aborts the whole system build. Upstream master still carries it. Until
    # it's gone, build the pm-package set from a patched source and inject it
    # through the module's pmPackages override seam — hermes-agent's own
    # packages.nix passes pmPackages explicitly for exactly this.
    # REMOVAL CONDITION: hermes-agent's nix/pm-packages.nix no longer mentions
    # patchelfFixed, or the .patch stops applying — then delete the
    # services block below, git rm the .patch file, and return to the default.
    programs.hermes-agent.desktop.enable = true;

    services.hermes-agent.package =
      let
        patched = pkgs.applyPatches {
          name = "hermes-agent-patched";
          src = inputs.hermes-agent;
          patches = [ ./hermes-pm-drop-stale-patchelf.patch ];
        };
        fixedPm = lib.filterAttrs (_: lib.isDerivation) (
          pkgs.callPackage "${patched}/nix/pm-packages.nix" { }
        );
      in
      inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        pmPackages = fixedPm;
      };
  };
}
