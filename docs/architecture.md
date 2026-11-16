# Architecture

how the flake is wired and what the module contract is.

## flake

`flake.nix` lists all flake inputs (nixpkgs-unstable, home-manager, sops-nix,
niri-nix, musnix, nix-index-database, doom-emacs, hermes-agent, ...) and builds
`nixosConfigurations` by **auto-discovery**: every directory under `hosts/`
becomes a configuration. adding a machine is adding a folder, nothing else.

each host evaluation wires the flake-input modules (home-manager, sops, musnix,
niri-nix, infract, nix-index-database) and imports `./modules` via the host
entry.

## the option tree

- `frogix.enable` — the master switch
- `frogix.user` — the primary user (no default: set it in your host)
- every module contributes `frogix.<area>.enable`, **defaulting to
  `frogix.enable`** — so enabling the suite enables every area, and the host
  opts *out* per area instead of in
- module-specific knobs default to sensible-universal values (UTC, noto fonts,
  firewall on, empty caches, null identities). ratholomew-specific values live
  in the host config as overrides

there are two trees because nixos and home-manager are separate module systems:

```
nixos  land: options.frogix.<area>.*        (modules/system/*)
hm     land: options.frogix.<area>.*        (modules/home-manager/*)
```

`frogix.enable` and `frogix.user` are declared in both and inherited nixos ->
hm by the wiring in `modules/default.nix` (`mkDefault`), so a host sets them
once.

personal values (git identity, storage paths) are
`types.nullOr str` with default `null` — nothing is written when unset, which
keeps the universal defaults clean. hardware facts that a module cannot work
without have no default at all: `frogix.screens.main` is required because
niri/pywal/vitrina reference it directly — forgetting it fails at eval time
instead of producing a broken config. the rest of `screens` stays optional:
`left`/`right` default to `null` (rules referencing an unset screen are
omitted) and `outputs` defaults to `[]` (niri runs every monitor at its
preferred mode, auto-positioned).

## module contract

a module file is one area, shaped like:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.frogix.<area>;
in
{
  options.frogix.<area> = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "...";
    };
    # ... knobs, default = the universal-sensible value
  };

  config = lib.mkIf cfg.enable {
    # actual nixos/home-manager config
  };
}
```

rules:

- module defaults are universal-sensible, never machine-specific
- structural paths (things the module itself installs) derive from
  `config.home.homeDirectory` (hm) or `config.frogix.user` (nixos), they are
  not knobs
- personal identity values are knobs with `null`/empty defaults
- files must be tracked by git: flakes only see tracked files
