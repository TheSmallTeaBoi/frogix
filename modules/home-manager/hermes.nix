{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  upstream = inputs.hermes-agent.packages.${system};

  # Upstream's nix/desktop.nix pins an electron-headers hash that went stale
  # against nixpkgs electron 43.5.1 (see hermes-electron-headers.patch).
  # Code still comes from the upstream flake input — only the one stale pin
  # is patched, and their desktop.nix is re-evaluated against it.
  # Drop `package` below once upstream fixes the pin.
  patchedSrc = pkgs.applyPatches {
    name = "hermes-agent-patched";
    src = inputs.hermes-agent.outPath;
    patches = [ ./hermes-electron-headers.patch ];
  };
  fixedDesktop = pkgs.callPackage (patchedSrc + "/nix/desktop.nix") {
    hermesAgent = upstream.default;
    hermesNpmLib = upstream.default.hermesNpmLib;
  };
in
{
  # hermes-desktop — the one Hermes piece this host keeps (Theo, 2026-09-21).
  # No hermes services or CLI live here anymore; the app is a client and gets
  # pointed at the home server. `programs.hermes-agent.enable` (the CLI) and
  # the old `chai` service-home wrapper are deliberately NOT set.
  programs.hermes-agent.desktop = {
    enable = true;
    package = fixedDesktop;
  };
}
