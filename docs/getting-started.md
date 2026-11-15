# Getting started

Installing frogix on a new machine. The whole flow assumes a working NixOS
install with flakes enabled (any recent NixOS has them) — you do the install
media dance yourself, frogix takes over after the first boot.

## 0. Try it in a VM first (optional)

```bash
git clone https://github.com/thesmallteaboi/frogix && cd frogix
nixos-rebuild build-vm --flake .#vm
./result/bin/run-frogix-vm-vm
```

log in as `demo` / `demo`. this VM runs the universal defaults with the desktop
stack disabled — the same flow you are about to do for real.

## 1. Clone

```bash
git clone <your fork or this repo> frogix && cd frogix
```

## 2. Create a host directory

```bash
mkdir -p hosts/mymachine
nixos-generate-config --no-modify   # writes ./hardware-configuration.nix here
mv hardware-configuration.nix hosts/mymachine/
```

then write `hosts/mymachine/default.nix`:

```nix
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  nixpkgs.hostPlatform = "x86_64-linux";   # match your cpu
  networking.hostName = "mymachine";
  system.stateVersion = "26.11";           # the release you are installing

  frogix = {
    enable = true;
    user = "you";
  };

  # first login needs a password; change it after booting
  users.users.you.initialPassword = "changeme";

  # minimal first build: turn the desktop stack off until you know it boots
  frogix."GUI-nvidia".enable = false;
  frogix.services.enable = false;
  frogix.niri = { enable = false; };  # hm-side, see docs/hosts.md for hm knobs
  frogix.romm.enable = false;
  frogix.sops.enable = false;
}
```

`nixos-generate-config` output can also be read straight into
`configuration.nix`-style files — anything host-specific belongs in the host
folder, anything generic belongs in `modules/` behind a knob (see
[hosts.md](hosts.md) for the split and [architecture.md](architecture.md) for
how the option tree works).

## 3. Build

```bash
git add -A    # flakes only see tracked files — this is not optional
nixos-rebuild switch --flake .#mymachine
```

the first build is the big one; after that, rebuilds only fetch what changed.

## 4. Log in and set your password

log in with the initial password you set, then `passwd`. delete the
`initialPassword` line from your host config afterwards so it is not sitting
around.

## 5. Tune

everything frogix does is a `frogix.*` option — see
[options.md](options.md) for the full list and defaults. ratholomew (the
machine frogix was built on) keeps its overrides in
[`hosts/ratholomew/configuration.nix`](../hosts/ratholomew/configuration.nix),
which doubles as a worked example.
