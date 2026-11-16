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

copy the template host and drop in your hardware scan:

```bash
cp -r hosts/template hosts/mymachine
nixos-generate-config --show-hardware-config > hosts/mymachine/hardware-configuration.nix
```

then edit `hosts/mymachine/default.nix`: hostname, username, and every TODO in
there. the template is a realistic desktop starting point — niri rice, nvidia +
sddm, gaming on by default, with the secrets-backed modules (`services` /
`romm` / `sops`) off until your age key is in place. the file comments explain
which knobs must travel together, and [`hosts/vm/`](../hosts/vm/) remains the
console-minimal extreme if you want a first build with the desktop off.

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
