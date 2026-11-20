# AGENTS.md

Instructions for AI agents working in **frogix**, a public modular NixOS
flake/distro. Everything is declarative; the whole system is one `frogix.*`
option tree. Read `docs/architecture.md`, `docs/hosts.md`, and
`docs/getting-started.md` before making structural changes.

## The one rule that decides where code goes

**Hardware-dependent facts belong in the specific host** (`hosts/<name>/`).
Monitors, disks/filesystems, kernel modules, network interface names, GPU
vendor, timezone, hostname, stateVersion, hardware scan output.

**Exception:** if making that hardware work needs workarounds (patched
packages, AppImage wrappers, custom derivations, udev rules, env hacks), it
becomes an **opt-in module** under `modules/`. Examples in-tree:
`nvidia.nix`, `vial.nix`, `xodus-nexus.nix`, `emeet-linux.nix`, `wine.nix`,
`hermes.nix`. A new hardware-specific module defaults **off** unless the
baseline desktop genuinely assumes that hardware; a fresh host must never get
broken hardware config just by setting `frogix.enable = true`.

Everything else — behaviour, packages, services, preferences — is a module
knob with a universal-sensible default.

## Non-negotiables

- **Declarative only.** No imperative setup scripts, no state written outside
  Nix options, no "run this once" steps. If something must happen at runtime,
  express it as a systemd unit / udev rule / activation script inside a module.
- **Module defaults are universal, never machine-specific.** Host-specific
  values are host overrides of those defaults.
- **Every `enable` defaults to `config.frogix.enable`** so the host opts *out*
  per area. Deliberate exceptions default `false` and carry a comment saying
  why (`frogix.pi`, `frogix.torbox`, `frogix."torbox-music-sync"`).
- **No enable passthroughs.** A module that would only set another
  module's/service's `enable` (droidcam, virt-manager/libvirtd, lazygit,
  zoxide, easyeffects, firefox, …) must not exist as a `frogix.*` area. Hosts
  enable those directly with plain `programs.*` / `services.*` options.
- **Never bump `stateVersion`.** `system.stateVersion` and
  `frogix.home.stateVersion` record the release the machine was first
  installed on. Bumping breaks application data.
- **Files must be git-tracked.** Flakes only see tracked files — `git add -A`
  before rebuilding or the build will not see your change.
- **Secrets never land in the store.** Use sops (`modules/system/secrets/`);
  see `modules/system/sops.nix` and `modules/system/pi.nix` for the patterns.
  `modules/unfree` is gitignored personal content — leave it alone.

## Repo map

```
flake.nix                 inputs + auto-discovery of hosts/ + docs.optionsMd generator
hosts/<name>/             one machine per directory; auto-registered
  default.nix             imports hardware-configuration.nix + ../../modules
  configuration.nix       (ratholomew only) host identity + frogix.* overrides
  hardware-configuration.nix  nixos-generate-config output, host-only
modules/
  default.nix             imports ./system + home-manager; wires the two trees
  system/<area>.nix       options.frogix.<area>  (NixOS side)
  system/default.nix      imports every system module — add new files here
  home-manager/<area>.nix options.frogix.<area>  (HM side)
  home-manager/default.nix  imports every HM module — add new files here
docs/                     architecture, hosts, getting-started, faq, options
```

The flake wires flake-input NixOS modules (`home-manager`, `sops-nix`,
`musnix`, `niri-nix`, `infract`, `nix-index-database`) in `hostModules` in
`flake.nix`. A new flake input that provides a NixOS module goes there; one
that provides a home-manager module goes in `modules/home-manager/default.nix`.

## The `frogix.*` option contract

Two separate module systems, two trees, same option names:

- NixOS side — `options.frogix.<area>.*` in `modules/system/*`, set directly
  from the host's `configuration.nix`.
- Home-manager side — `options.frogix.<area>.*` in `modules/home-manager/*`,
  set under `home-manager.users.<user>.frogix.*`.

`frogix.enable` and `frogix.user` are declared in both; `modules/default.nix`
inherits nixos → hm with `lib.mkDefault`, so a host sets them once.

A module file is exactly one area, shaped like:

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
      description = "...";        # this prose IS the docs — see below
    };
    # ... knobs, default = the universal-sensible value
  };

  config = lib.mkIf cfg.enable {
    # actual nixos/home-manager config
  };
}
```

Rules for options:

- Option `description`s are the only place module prose lives; they are
  rendered into `docs/options.md`. Write them for a user of the option.
- Personal identity values (git name/email, paths, matrix id) are knobs typed
  `lib.types.nullOr lib.types.str` with `default = null`; nothing is written
  when unset.
- Structural paths the module itself installs derive from
  `config.home.homeDirectory` (hm) or `config.frogix.user` (nixos) — they are
  not knobs.
- A value a module cannot work without has **no default**: `frogix.user`,
  `frogix.home.stateVersion`, and `frogix.screens.main` are required and fail
  at eval time if unset. Prefer this over a broken default.
- Areas whose name has a dash are quoted attrs: `frogix."emeet-linux"`,
  `frogix."xodus-nexus"`.
- Coupled features assert instead of silently breaking. If a module needs
  sops, add an `assertions` entry with a message naming the modules that must
  travel together (see `modules/system/services.nix`, `torbox.nix`).

## Recipes

### Change or add a module

1. Edit/create `modules/system/<area>.nix` or
   `modules/home-manager/<area>.nix`.
2. Register the file in that tree's `default.nix` `imports` list.
3. Follow the contract above. Keep the module self-contained.
4. If you added a required (no-default) option, add a placeholder for it in
   `flake.nix`'s `nixosDocModule` / `hmDocModule` — otherwise the docs eval
   fails. `frogix.user`, `frogix.home.stateVersion`, `home.username`,
   `home.homeDirectory`, and `home.stateVersion` are already seeded there.
5. Regenerate docs and format (commands below).

### Add a host

Copy `hosts/template/` to `hosts/<name>/`, replace
`hardware-configuration.nix` with `nixos-generate-config` output, fill in the
TODOs (hostname, user, stateVersion, monitor name), `git add -A`, rebuild.
Nothing else to register — the flake discovers the directory. A new host uses
the current release for both `stateVersion`s and never changes it again.
`hosts/vm/` is the console-minimal extreme; `hosts/ratholomew/` is the worked
desktop example.

### Add a workaround / opt-in module

Keep it one file under `modules/system/` (or `home-manager/`). Pin external
sources by hash (`fetchurl`, `fetchFromGitHub`, `appimageTools`); bumping is
documented in a header comment. Default `enable = false` and explain in the
option description why the module exists and when it can be deleted. The
header comments in `vial.nix`, `xodus-nexus.nix`, and `hermes.nix` are the
style to match: explain the *why*, cite the upstream behaviour, and state a
removal condition for anything patched.

### Touch the pi provider extension

`modules/system/pi/surplus-provider.ts` registers the `surplus` provider
(live catalog from `/v1/models`, key-scoped prices, `/models-by-price`). It is
passed to pi as `--extension <store path>`, so **editing it changes nothing
until `nixos-rebuild switch`** — a running `pi` keeps the old store copy.

- surplus is a marketplace router: the upstream seller differs per request, so
  a role/parameter one seller tolerates can be a hard 400 from another. Keep
the request shape conservative (`COMPAT` pins the instruction role to
`system`, because reasoning models otherwise get `developer`, which
plain-schema sellers reject intermittently).
- Verify a provider change without rebuilding by passing the repo file again:
`pi --extension ./modules/system/pi/surplus-provider.ts -p --model … "hi"`
(a later `--extension` re-registers the provider and wins). Add a throwaway
`before_provider_request` extension to log the serialized payload.

## Docs and commands

`docs/options.md` is generated from the live option trees; the header prose is
`docs/options.header.md`. **After touching any module's options, regenerate:**

```bash
nix eval --raw .#docs.optionsMd > docs/options.md
```

Other commands:

```bash
nix fmt                                   # nixfmt-tree, the flake formatter — always run
nixos-rebuild switch --flake .#<host>     # apply a host
nixos-rebuild build-vm --flake .#vm       # cheap eval/build smoke test
git add -A                                # required before any rebuild
```

Build the VM or run `nix fmt` before declaring work done. There is no CI; the
flake's own eval is the check.

## Style

- Format with `nixfmt-tree` (`nix fmt`). Two-space indent.
- Comments explain *why*, not *what*. Reference dates and removal conditions
  for temporary hacks, as the existing modules do.
- Prefer `lib.mkIf`, `lib.mkDefault`, `lib.mkForce` deliberately — `mkDefault`
  is for letting a host win, `mkForce` only when overriding upstream.
- Use `pkgs.writeShellApplication` (with `runtimeInputs`) over raw
  `writeShellScript`; use `lib.getExe` / `lib.getExe'` for binaries.
- Don't add a `frogix.*` toggle for a feature that has no frogix-specific
  value — enable the upstream option directly in the host.
- Keep the repo warning-free: fix renamed/deprecated options rather than
  suppressing them.
