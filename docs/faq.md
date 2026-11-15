# FAQ and gotchas

### rebuild says `Path ... is not tracked by Git`

flakes only see git-tracked files. `git add -A` before rebuilding — new files
are invisible until you do.

### the firewall

`frogix.networkd.firewall` defaults to **on** (the universal default). gaming
desktops that need open ports turn it off in their host config — ratholomew
does.

### JACK apps broke

`services.pipewire.jack.enable` is deprecated upstream (it sets a global
`LD_LIBRARY_PATH`, which is global impurity). run JACK apps through the
`pw-jack` wrapper instead: `pw-jack <app>`.

### my home files got a `.back` extension

home-manager replaced files it manages. the previous version is kept as
`<file>.back`. this comes from `home-manager.backupFileExtension` in the
wiring.

### changing `stateVersion`

do not. `frogix.home.stateVersion` / `system.stateVersion` record the release
the machine was **first installed** on; bumping it does not upgrade anything
and can break application data.

### sops secrets

`frogix.sops.enable` gates the sops setup (`modules/system/sops.nix`), which
expects the age key at `~/.config/sops/age/keys.txt` (generated on first boot)
and the secret file in `modules/system/secrets/`. a minimal host without
secrets should leave it off.

### `sudo nixos-rebuild switch --flake .` says the flake is dirty

that is just the warning that uncommitted changes exist. builds work from the
working tree; commit when you are happy.

### rebuild built nothing but eval warnings appeared

evaluation warnings (renamed options, deprecated flags) show on every rebuild
until fixed — they are config-level, not build-level. frogix keeps itself
warning-free; if you add a module that reintroduces one, upstream renamed an
option and the module needs the new name.
