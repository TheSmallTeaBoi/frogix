# Hosts

`hosts/` is one folder per machine. the flake turns every directory in it into
a `nixosConfigurations.<name>` automatically — there is nothing to register.

## what lives where

the split rule: **defaults are universal, hosts carry differences.**

- module defaults describe a sensible machine of that kind
- the host folder contains only what makes that machine different: hostname,
  platform, stateVersion, hardware file, and the `frogix.*` overrides

a host directory looks like:

```
hosts/ratholomew/
├── default.nix                  # entry point: imports modules + the files below
├── configuration.nix            # host identity + frogix.* overrides
└── hardware-configuration.nix   # from nixos-generate-config
```

`hosts/vm/` is the minimal example: console-only, universal defaults, a dozen
opt-outs. `hosts/template/` is the realistic desktop starting point new hosts
are copied from: universal defaults on, TODOs where the personal facts go (see
[getting-started.md](getting-started.md)); the placeholder hardware file lets
you smoke-test the build with `nixos-rebuild build-vm --flake .#template`.

## the two option trees

`frogix.*` exists twice, because nixos and home-manager are separate module
systems:

- **nixos side**: set from the host's `configuration.nix` directly —
  `frogix.networkd.interfaces`, `frogix.romm.libraryDir`, ...
- **home-manager side**: set under `home-manager.users.<user>.frogix.*` —
  `frogix.screens`, `frogix.git.email`, `frogix.beets.libraryDir`, ...

`frogix.enable` and `frogix.user` are set once on the nixos side and inherited
into the hm tree automatically.

## ratholomew, as a worked example

the interesting part of
[`hosts/ratholomew/configuration.nix`](../hosts/ratholomew/configuration.nix):

```nix
frogix = {
  enable = true;
  user = "theo";

  core = {
    timeZone = "America/Buenos_Aires";         # universal default is UTC
    fonts = with pkgs; [ noto-fonts noto-fonts-lgc-plus google-fonts ];  # maple-mono.NF (the rice font) ships with core
    iconPackages = with pkgs; [ numix-icon-theme-circle colloid-icon-theme ];
    java.enable = true;                        # universal default is off
  };

  nix = {
    caches."https://cache.nixos-cuda.org" =
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=";
    permittedInsecurePackages = [ "pnpm-10.29.2" "qutebrowser-3.7.0" "quickjs-2025-09-13-2" ];
    documentation = false;                     # universal default is on
  };

  networkd = { interfaces = [ "enp38s0" ]; firewall = false; };  # firewall default is on
  services = {
    navidrome.musicFolder = "/storage/Music/";
    navidrome.address = "0.0.0.0";             # universal default is 127.0.0.1
    syncthing.devices = { Phone = "..."; JTB = "..."; /* ... */ };
    syncthing.folders = { Obsidian = "/storage/Personal/obsidian"; /* ... */ };
  };

  romm = { libraryDir = "/storage/Roms"; biosDir = "/storage/Bios" };
  "torbox-music-sync".musicDir = "/storage/Music";
  display.autoLogin = true;                    # universal default is off
};

# host service choices — plain NixOS options, NOT frogix.* toggles (services
# with no frogix-specific value are enabled directly on each host):
programs.droidcam.enable = true;
programs.dconf.enable = true;
programs.virt-manager.enable = true;
users.extraGroups.libvirtd.members = [ "theo" ];
virtualisation.libvirtd.enable = true;
virtualisation.spiceUSBRedirection.enable = true;

home-manager.users.theo = {
  frogix.home.stateVersion = "23.11";          # 23.11 = the release ratholomew was installed on;
                                               # a NEW host uses the current release — never bump afterwards
  frogix.screens.main = "DP-4";
  frogix.screens.left = "HDMI-A-1";
  frogix.screens.right = "HDMI-A-3";
  # logical widths per role: niri.nix computes the x offsets in
  # left -> main -> right order (niri sorts unpositioned outputs by name, so
  # the arrangement must be explicit); per-output mode/transform/position
  # overrides live under frogix.screens.outputs
  frogix.screens.autoLayout.widths = { left = 768; main = 1920; right = 1366; };
  # HDMI-A-3 returns in the wrong mode from DPMS, so it is never blanked;
  # hyprlock's black background covers it at idle instead
  frogix.niri.keepOnOutputs = [ "HDMI-A-3" ];
  frogix.wallpapersDir = "/storage/Walls";
  # host service choices, hm side (not frogix.* toggles):
  services.easyeffects = { enable = true; preset = "Voice Moondrop"; };
  programs.lazygit.enable = true;
  programs.zoxide = { enable = true; options = [ "--cmd cd" ]; };
  frogix.audio.mixerElement = "Emotiva Little Ego";
  frogix.beets = { libraryDir = "/storage/Music/"; convertDest = "/storage/music-lossier/"; };
  frogix.git = { email = "theoiturri@tutanota.com"; name = "TheSmallTeaBoi"; };
  frogix.iamb.matrixId = "@thesmallteaboi:matrix.org";
  frogix.sunshine.output = "DP-3";
};
```

every line is an override of a universal default — on a fresh machine you write
your own values or leave the lines out entirely.

## the VM

[`hosts/vm/`](../hosts/vm/) is the minimal build: console-only, `user = "demo"`,
UTC, most modules off. build and run it with:

```bash
nixos-rebuild build-vm --flake .#vm
./result/bin/run-frogix-vm-vm
```
