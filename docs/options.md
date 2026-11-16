# `frogix.*` options

the full option reference. every `enable` defaults to `frogix.enable`, so a
host that sets only `frogix.enable = true` gets the whole suite; everything
below can be overridden per host. values shown are the **universal defaults** —
ratholomew overrides many of them (see [hosts.md](hosts.md)).

this page is generated from the live option tree and matches the code.

## top level

| option | type | default | description |
|---|---|---|---|
| `frogix.enable` | bool | false | master switch for the whole suite |
| `frogix.user` | string | *(no default)* | the primary user — required |

## system modules (nixos side)

### `frogix.boot`
| option | type | default |
|---|---|---|
| `enable` | bool | master |

latest kernel, ntsync, quiet boot, systemd-boot, memlock ulimit, performance governor.

### `frogix.networkd`
| option | type | default |
|---|---|---|
| `enable` | bool | master |
| `firewall` | bool | true |
| `interfaces` | list of str | `[]` (dhcpcd manages all) |

dhcpcd + iwd network stack.

### `frogix.nix`
| option | type | default |
|---|---|---|
| `enable` | bool | master |
| `gc.automatic` / `gc.dates` / `gc.options` | bool / str / str | true / "weekly" / "--delete-older-than 3d" |
| `optimise.automatic` / `optimise.dates` | bool / list | true / ["06:00"] |
| `experimentalFeatures` | list of str | ["nix-command", "flakes"] |
| `trustedUsers` | list of str | ["root", "@wheel"] |
| `caches` | attrs of str (url -> key) | `{}` |
| `permittedInsecurePackages` | list of str | `[]` |
| `documentation` | bool | true |
| `ld.enable` | bool | master |
| `comma.enable` | bool | master |

also sets `nixpkgs.config.allowUnfree`.

### `frogix.core`
| option | type | default |
|---|---|---|
| `enable` | bool | master |
| `timeZone` | str | "UTC" |
| `zram.memoryPercent` / `zram.algorithm` | int / str | 50 / "zstd" |
| `fonts` | list of package | noto-fonts, noto-fonts-color-emoji |
| `iconPackages` | list of package | `[]` |
| `java.enable` | bool | false |

also: qt enabled, uinput/bluetooth/opentabletdriver hardware, and
`hm-backup-sweep` (clears stale home-manager `.back` files before activation so
app-rewritten configs can't wedge the switch).

### `frogix.shell`
| option | type | default |
|---|---|---|
| `enable` | bool | master |
| `editor` / `browser` | str | "emacsclient -c" / "qutebrowser" |

fish + direnv + the core session environment (EDITOR/VISUAL/BROWSER).

### `frogix.users`
| option | type | default |
|---|---|---|
| `enable` | bool | master |
| `extraGroups` | list of str | ["wheel", "input", "uinput", "audio", "gamemode", "bluetooth"] |

defines `users.users.<frogix.user>` as a normal user. note: groups must exist
— if you disable a module that owns a group (e.g. gamemode), remove it here
too.

### `frogix.services`
the desktop service stack: navidrome, syncthing, pipewire, sunshine,
tailscale, dbus, sshd, udev rules, gnome-keyring, gvfs, fstrim, earlyoom,
input-remapper, mysql.

| option | type | default |
|---|---|---|
| `enable` | bool | master |
| `navidrome.musicFolder` | nullOr str | null (nixpkgs default) |
| `navidrome.address` | str | "127.0.0.1" |
| `syncthing.dataDir` / `configDir` | str | derived from `frogix.user` |
| `syncthing.devices` | attrs of str | `{}` — device name -> id |
| `syncthing.folders` | attrs of str | `{}` — folder label -> path |
| `vialSerial` | nullOr str | null |

### `frogix.romm`
| option | type | default |
|---|---|---|
| `enable` | bool | master |
| `libraryDir` / `biosDir` | nullOr str | null (no bind mount) |
| `resourcesDir` | nullOr str | null (scraped media lives on the root fs) |
| `useTosec` | bool | false |

romm + its postgres/redis backing services. the binds map the host collection
into romm's library paths; `resourcesDir` keeps multi-GB scraped media off the
root fs; `useTosec` deploys the TOSEC folder -> slug mapping.

### toggles with only `enable`
`frogix.boot`-style single-knob modules: `droidcam`, `musicMaking` (musnix
realtime tweaks + the plugin rack), `steam` (with the steam chroot libs),
`wine`, `virt` (virt-manager/libvirtd), `sops` (age key at
`~/.config/sops/age/keys.txt`, generated), `torbox` (webdav mount,
`mountPoint` knob, default **off**), `"torbox-music-sync"` (`musicDir`,
`remotePath` knobs, default **off**),
`"xodus-nexus"`, `"emeet-linux"` (webcam preset replay), `"GUI-nvidia"`
(nvidia stack + sddm + niri session defaults — on with the suite; the
`autoLogin` knob defaults off).

### `frogix.packages` — opt-out packs
`packages.enable` is the master switch; each pack below follows it until
toggled off: `terminal` (core CLI), `rice` (pywal/mako/rofi), `coding`
(nix-alien/devenv/sops), `keyboard` (qmk/vial), `gui` (file manager,
screenshots, e-books, capture), `music` (listening/library tools — the
*production* plugin rack lives in `musicMaking`), `piracy` (aria2, stremio).
game packages ship with `frogix.gaming` (gamemode + gpu-screen-recorder +
the game rack) rather than a pack.

## home-manager modules (set under `home-manager.users.<user>.frogix.*`)

### `frogix.home`
| option | type | default |
|---|---|---|
| `enable` | bool | master |
| `stateVersion` | str | *(no default — required)* |

the release the machine was first installed on. **never bump it.**

### shared hardware facts
| option | type | default |
|---|---|---|
| `frogix.screens.main` | str | **required** — the primary monitor; niri/pywal/vitrina reference it directly |
| `frogix.screens.left` / `.right` | nullOr str | null (niri/pywal use them; rules referencing an unset screen are omitted) |
| `frogix.screens.outputs` | list of attrs | `[]` (optional) — niri monitor rules (mode/scale/position/transform); host hardware layout. empty = niri defaults: preferred mode, auto position |
| `frogix.wallpapersDir` | str | `~/Pictures/Wallpapers` — seeded with the bundled `wallpaper.png` while it holds no files |

### identity knobs (null = feature writes nothing)
| option | type | default |
|---|---|---|
| `frogix.git.email` / `frogix.git.name` | nullOr str | null |
| `frogix.iamb.matrixId` | nullOr str | null |
| `frogix.easyeffects.preset` | nullOr str | null |
| `frogix.audio.mixerElement` | nullOr str | null (no ACP override written) |
| `frogix.emacs.orgDirectory` | nullOr str | null (doom default `~/org`) |

### areas with knobs
| area | knob | default |
|---|---|---|
| `frogix.beets` | `libraryDir` / `convertDest` | `~/Music` / `~/Music-lossy` |
| `frogix.sunshine` | `output` | null (auto-detect) |

### toggles with only `enable`
`audio`, `bottom`, `browser` (qutebrowser + firefox), `desktop` (user desktop
entries), `emacs` (doom), `gtk`, `hermes` (desktop client), `home` (hm
identity), `iamb`, `kitty`, `lazygit`, `mako` (daemon stays off), `niri`
(full rice: hypridle/hyprlock, binds), `pywal` (set-wal engine + every
consumer template), `rofi`, `shell` (fish + starship + tmux autostart),
`sunshine` (gamescope launcher on PATH; conf + apps.json are
sunshine-owned, not managed), `tmux`, `vesktop`, `vitrina` (quickshell),
`xdg` (mime defaults), `zoxide`.

`frogix.user` is inherited from the nixos side; hm modules never hardcode a
username.
