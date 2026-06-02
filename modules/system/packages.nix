{
  pkgs,
  inputs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Ricing stuff
    catppuccin-papirus-folders
    waybar-mpris
    mako
    rofi

    # Terminal tools
    clipse
    wl-clipboard
    fzf
    ripgrep
    # neofetch # They deprecated my boy
    fastfetch
    wget
    git
    pulsemixer
    bottom
    eza
    micro
    file
    beets
    yt-dlp
    rclone
    ffmpeg
    qmk
    qmk-udev-rules
    playerctl
    picotts
    mp3val
    flac

    vial

    # Coding, I guess
    inputs.nix-alien.packages.x86_64-linux.nix-alien

    devenv
    gnome-keyring

    # Random GUI stuff
    feh
    obsidian # /shrug
    pandoc
    warpinator
    grimblast
    appimage-run
    nemo

    xwayland-satellite

    heroic-unwrapped

    # Art?
    obs-studio

    # compressed stuff
    xarchiver
    unar
    unzip
    zip
    p7zip

    # Game stuff

    lsfg-vk
    lsfg-vk-ui
    steamtinkerlaunch
    gpu-screen-recorder-gtk

    (prismlauncher.override {
      jdks = with pkgs; [
        jdk21
        jdk25
        jdk17
        jdk8
      ];
    })

    beammp-launcher
    flightgear

    # Emulation {
    # retroarch-full
    pcsx2
    # flycast
    ppsspp
    # torzu # I will not forget you.
    # }

    logmein-hamachi # my beloved
    parsec-bin # actual black magic.
    protontricks
    mangohud

    # Piracy stuff :)
    aria2
    jellyfin-desktop
    stremio-linux-shell

    # Music stuff
    nicotine-plus
    picard
    mpv
    feishin

    # Music making
    ardour

    AMB-plugins
    aether-lv2
    airwindows
    autotalent
    bchoppr
    calf
    caps
    carla
    chow-centaur
    chow-kick
    chow-phaser
    chow-tape-model
    cmt
    dexed
    distrho-ports
    dragonfly-reverb
    drumkv1
    eq10q
    geonkick
    guitarix
    helm
    infamousPlugins
    lsp-plugins
    mod-distortion
    ninjas2
    noise-repellent
    oxefmsynth
    quadrafuzz
    rubberband
    samplv1
    sfizz
    sorcer
    synthv1
    tap-plugins
    vital
    wolf-shaper
    x42-plugins
    zam-plugins
    zita-at1
    zynaddsubfx

    # Misc
    btrfs-progs # btrfs my beloved
    rofi-power-menu
  ];
}
