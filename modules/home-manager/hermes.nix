{ ... }:
{
  # hermes-desktop — the one Hermes piece this host keeps (Theo, 2026-09-21).
  # No hermes services or CLI live here anymore; the app is a client and gets
  # pointed at the home server. `programs.hermes-agent.enable` (the CLI) and
  # the old `chai` service-home wrapper are deliberately NOT set.
  #
  # 2026-11-06: upstream's desktop.nix now takes electron headers from
  # nixpkgs' own electron.headers derivation (tracks every bump, no stale
  # hash), so the local hermes-electron-headers patch + repackage is gone
  # and the module's default package is used as-is.
  programs.hermes-agent.desktop.enable = true;
}
