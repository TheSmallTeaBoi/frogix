# `frogix.*` options

The full option reference, **generated from the live option tree** — this is
what the modules declare, not a hand-maintained copy, so it cannot drift from
the code.

Every `enable` defaults to `frogix.enable`, so a host that sets only
`frogix.enable = true` gets the whole suite; everything below can be
overridden per host. Values shown are the **universal defaults** —
ratholomew overrides many of them (see [hosts.md](hosts.md)).

Options are listed alphabetically and split by tree: system modules first,
home-manager modules second (the latter are set under
`home-manager.users.<user>.frogix.*`).

After touching a module's options, regenerate this page (module prose lives
in the option descriptions, not here):

```bash
nix eval --raw .#docs.optionsMd > docs/options.md
```

# system modules (nixos side)

## frogix.enable



Whether to enable the frogix module suite.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```




## frogix.packages.enable



the frogix package sets (packs below follow this master switch)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.packages.coding



dev tooling (nix-alien, devenv, secret/keyring CLIs)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.packages.gui



personal GUI apps (obsidian, calibre, warpinator, obs, pandoc)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.packages.keyboard



QMK firmware + vial tooling



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.packages.music



music listening/library tools (production plugins live in frogix.musicMaking)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.packages.piracy



aria2 + stremio :)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.packages.rice



ricing CLI (pywal, mako, rofi)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.packages.terminal



core CLI tools (fetch, browse, clipboard, av wrangling, compression)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.boot.enable

frogix boot: latest kernel, ntsync, quiet splash, systemd-boot, memlock ulimit and performance governor



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.core.enable



desktop machine defaults: timezone, zram, fonts, qt, peripheral
hardware (uinput/bluetooth/opentabletdriver), and the hm-backup-sweep
that clears stale home-manager .back files before activation so
app-rewritten configs can’t wedge the switch



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.core.fonts



extra system font packages (the rice’s Maple Mono NF ships regardless — kitty/vitrina/emacs/qt hard-code it)



*Type:*
list of package



*Default:*

```nix
[
  <derivation noto-fonts-2026.11.01>
  <derivation noto-fonts-color-emoji-2.051>
]
```




## frogix.core.iconPackages



icon theme packages installed system-wide



*Type:*
list of package



*Default:*

```nix
[ ]
```




## frogix.core.java.enable



programs.java for the desktop



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.core.timeZone



system timezone



*Type:*
string



*Default:*

```nix
"UTC"
```




## frogix.core.zram.algorithm



zram compression algorithm



*Type:*
string



*Default:*

```nix
"zstd"
```




## frogix.core.zram.memoryPercent



zram swap size as percent of RAM



*Type:*
signed integer



*Default:*

```nix
50
```




## frogix.display.enable



sddm + the niri session, and the session plumbing its config hard-references



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.display.autoLogin



autologin the frogix user on the sddm niri session (off by default)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.droidcam.enable



droidcam webcam + dconf



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.emeet-linux.enable



emeet-linux webcam control panel with hotplug preset replay



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.gaming.enable



gamemode, gpu-screen-recorder and the game package rack



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.input.enable



libinput defaults: flat mouse accel, no middle emulation



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.musicMaking.enable



musnix realtime audio tweaks + the plugin rack (LV2/LADSPA/VST)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.networkd.enable



dhcpcd + iwd network stack



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.networkd.firewall



keep the firewall disabled (the frogix default)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.networkd.interfaces



interfaces dhcpcd is allowed to manage (empty = all)



*Type:*
list of string



*Default:*

```nix
[ ]
```




## frogix.nix.enable



nix daemon settings, caches and nix tooling defaults (also sets nixpkgs.config.allowUnfree)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.nix.caches



extra binary caches: substituter url -> signing key



*Type:*
attribute set of string



*Default:*

```nix
{ }
```




## frogix.nix.comma.enable



comma on top of the nix-index database



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.nix.documentation



enable the NixOS documentation (off by default: I usually have internet)



*Type:*
boolean



*Default:*

```nix
true
```




## frogix.nix.experimentalFeatures



nix experimental-features to enable



*Type:*
list of string



*Default:*

```nix
[
  "nix-command"
  "flakes"
]
```




## frogix.nix.gc.automatic



run nix-collect-garbage on a schedule



*Type:*
boolean



*Default:*

```nix
true
```




## frogix.nix.gc.dates



systemd calendar for the gc timer



*Type:*
string



*Default:*

```nix
"weekly"
```




## frogix.nix.gc.options



extra flags passed to nix-collect-garbage



*Type:*
string



*Default:*

```nix
"--delete-older-than 3d"
```




## frogix.nix.ld.enable



programs.nix-ld for prebuilt binaries



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.nix.optimise.automatic



run nix-store --optimise on a schedule



*Type:*
boolean



*Default:*

```nix
true
```




## frogix.nix.optimise.dates



systemd calendar for the optimise timer



*Type:*
list of string



*Default:*

```nix
[
  "06:00"
]
```




## frogix.nix.permittedInsecurePackages



nixpkgs.config.permittedInsecurePackages



*Type:*
list of string



*Default:*

```nix
[ ]
```




## frogix.nix.trustedUsers



nix trusted-users



*Type:*
list of string



*Default:*

```nix
[
  "root"
  "@wheel"
]
```




## frogix.nvidia.enable



nvidia graphics stack: driver, vaapi env and firefox hw accel



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.romm.enable



RomM game library + nginx vhost, with its postgres/redis backing services



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.romm.biosDir



host BIOS collection bind-mounted into the container path



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.romm.libraryDir



host ROM collection bind-mounted into the container path



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.romm.listenAddress



address the RomM API binds



*Type:*
string



*Default:*

```nix
"0.0.0.0"
```




## frogix.romm.port



port the RomM API listens on



*Type:*
16 bit unsigned integer; between 0 and 65535 (both inclusive)



*Default:*

```nix
8080
```




## frogix.romm.resourcesDir



host path for scraped media (covers, screenshots); keeps multi-GB scraper output off the root fs



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.romm.useTosec



deploy the bundled config.yml mapping TOSEC-named library folders to RomM platform slugs



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.romm.virtualHost



nginx vhost serving RomM



*Type:*
string



*Default:*

```nix
"romm.localhost"
```




## frogix.services.enable



desktop service stack: navidrome, syncthing, pipewire, sunshine,
tailscale, dbus, sshd, udev rules, gnome-keyring, gvfs, fstrim,
earlyoom, input-remapper, mysql



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.services.navidrome.address



navidrome listen address (0.0.0.0 exposes it to the network)



*Type:*
string



*Default:*

```nix
"127.0.0.1"
```




## frogix.services.navidrome.musicFolder



navidrome library root (null = nixpkgs default)



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.services.syncthing.configDir



syncthing config dir



*Type:*
string



*Default:*

```nix
"/home/user/.config/syncthing"
```




## frogix.services.syncthing.dataDir



syncthing default sync dir



*Type:*
string



*Default:*

```nix
"/home/user/Documents"
```




## frogix.services.syncthing.devices



syncthing device name -> device id



*Type:*
attribute set of string



*Default:*

```nix
{ }
```




## frogix.services.syncthing.folders



syncthing folder label -> path



*Type:*
attribute set of string



*Default:*

```nix
{ }
```




## frogix.services.vialSerial



serial fragment matched by the Vial udev rule (null = no vial rule)



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.shell.enable



fish shell, direnv and the core session environment



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.shell.browser



BROWSER in the session environment



*Type:*
string



*Default:*

```nix
"qutebrowser"
```




## frogix.shell.editor



EDITOR/VISUAL in the session environment



*Type:*
string



*Default:*

```nix
"emacsclient -c"
```




## frogix.sops.enable



sops-nix with the frogix secret set (age key at ~/.config/sops/age/keys.txt, generated on demand)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.steam.enable



steam, steam hardware, gamescope session and the steam chroot libs



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.torbox.enable



TorBox WebDAV rclone mount



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.torbox.mountPoint



where the webdav remote is mounted



*Type:*
string



*Default:*

```nix
"/mnt/torbox"
```




## frogix.torbox-music-sync.enable



weekly TorBox -> beets music sync



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.torbox-music-sync.musicDir



beets library root the sync imports into



*Type:*
string



*Default:*

```nix
"/home/user/Music"
```




## frogix.torbox-music-sync.remotePath



path inside the torbox remote to sync from



*Type:*
string



*Default:*

```nix
"nebula"
```




## frogix.user



the primary user the frogix modules configure (no default: set it in your host)



*Type:*
string




## frogix.users.enable



define the frogix.user account (password is set with passwd)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.users.extraGroups



groups the primary user is a member of. the groups must exist —
disabling a module that owns one (e.g. gaming and “gamemode”) means
removing it here too



*Type:*
list of string



*Default:*

```nix
[
  "wheel"
  "input"
  "uinput"
  "audio"
  "gamemode"
  "bluetooth"
]
```




## frogix.virt.enable



virt-manager / libvirtd stack with spice usb redirection



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.wine.enable



the full wine family + winetricks



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.xodus-nexus.enable



Xodus Nexus (PC Game Pass) AppImage wrapper



*Type:*
boolean



*Default:*

```nix
false
```




# home-manager modules (set under home-manager.users.<user>.frogix.*)

## frogix.enable



Whether to enable frogix home-manager modules.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```




## frogix.audio.enable

hardware mixer path so ACP binds the DAC’s analog volume



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.audio.mixerElement



ALSA simple element the mixer path binds hardware volume to



*Type:*
string



*Default:*

```nix
"Emotiva Little Ego"
```




## frogix.beets.enable



beets music tagger config



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.beets.convertDest



beets convert plugin destination



*Type:*
string



*Default:*

```nix
"/home/user/Music-lossy"
```




## frogix.beets.libraryDir



beets library directory



*Type:*
string



*Default:*

```nix
"/home/user/Music"
```




## frogix.bottom.enable



bottom system monitor with gpu + fast refresh



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.browser.enable



qutebrowser + firefox with the pywal rice



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.desktop.enable



user desktop entries



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.easyeffects.enable



easyeffects with a default preset



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.easyeffects.preset



easyeffects preset applied on start (null = leave unset)



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.emacs.enable



doom emacs + emacs server



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.emacs.orgDirectory



org directory injected into the doom config (org, org-roam and the roam db live here)



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.git.enable



git with frogix defaults



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.git.email



git user.email (null = don’t set)



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.git.name



git user.name (null = don’t set)



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.gtk.enable



gtk/qt theme stack and cursor (rice pins stay module defaults)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.hermes.enable



hermes-desktop client with the patched pm-package seam



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.home.enable



home-manager identity for the frogix user (username and homeDirectory come from the wrapper)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.home.stateVersion



home-manager stateVersion: the NixOS release this machine was FIRST
installed on. never bump it afterwards



*Type:*
string




## frogix.iamb.enable



iamb matrix client config



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.iamb.matrixId



matrix account iamb logs into (null = no profile block)



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.kitty.enable



kitty terminal wired to the pywal palette



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.lazygit.enable



lazygit



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.mako.enable



mako notification daemon config (daemon itself stays disabled)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.niri.enable



the full niri rice: compositor config, keybinds, hypridle/hyprlock



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.pywal.enable



pywal16 rice engine: set-wal, light mode and every consumer template



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.pywal.cycleInterval



minutes between wallpaper shuffles (0 = pick one at login and stay on it)



*Type:*
signed integer



*Default:*

```nix
15
```




## frogix.rofi.enable



rofi launcher with the vitrina theme



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.screens



monitor names as niri/wlpicker see them



*Type:*
submodule




## frogix.screens.autoLayout



compute niri output positions from screen widths — niri
auto-placement sorts unpositioned outputs by name, so the
physical left -> main -> right arrangement must be explicit



*Type:*
null or (submodule)



*Default:*

```nix
null
```




## frogix.screens.autoLayout.widths



logical (post-scale/transform) width per role — niri computes
x offsets cumulatively in left -> main -> right order and
top-aligns (y = 0); a position the host wrote still wins



*Type:*
attribute set of signed integer



*Default:*

```nix
{ }
```




## frogix.screens.left



the left monitor — niri/pywal use it; rules referencing an unset screen are omitted



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.screens.main



the main monitor — mandatory; niri/pywal/vitrina reference it directly



*Type:*
string




## frogix.screens.outputs



niri monitor rules (mode, scale, position, transform, per-screen layout) — host hardware layout



*Type:*
list of (attribute set)



*Default:*

```nix
[ ]
```




## frogix.screens.right



the right monitor — niri/pywal use it; rules referencing an unset screen are omitted



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.shell.enable



fish + starship + tmux autostart shell stack



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.sunshine.enable



sunshine game streaming with the gamescope launcher on PATH (sunshine owns conf + apps.json, not managed)



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.sunshine.output



monitor sunshine captures (null = sunshine auto-detects)



*Type:*
null or string



*Default:*

```nix
null
```




## frogix.tmux.enable



tmux with the pywal status theme



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.user



the primary user (inherited from the NixOS side by default)



*Type:*
string




## frogix.vesktop.enable



vesktop with hw accel and arRPC



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.vitrina.enable



quickshell shell packages + config



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.wallpapersDir



directory wallpapers are shuffled from; seeded with the bundled
wallpaper.png while it holds no files



*Type:*
string



*Default:*

```nix
"/home/user/Pictures/Wallpapers"
```




## frogix.xdg.enable



mime default applications



*Type:*
boolean



*Default:*

```nix
false
```




## frogix.zoxide.enable



zoxide with cd replacement



*Type:*
boolean



*Default:*

```nix
false
```



