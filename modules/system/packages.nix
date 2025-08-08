{
  pkgs,
  inputs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Ricing stuff
    nerd-fonts.fira-code
    catppuccin-papirus-folders
    waybar-mpris
    mako
    rofi

    # Terminal tools
    clipse
    wl-clipboard
    fzf
    ripgrep
    neofetch
    wget
    rclone
    git
    pulsemixer
    bottom
    eza
    file
    # beets # FIXME currently broken.
    yt-dlp
    ffmpeg
    iamb
    qmk
    qmk-udev-rules
    playerctl
    picotts
    mp3val
    flac

    vial

    # Coding, I guess
    inputs.self.packages.x86_64-linux.neovim
    inputs.nix-alien.packages.x86_64-linux.nix-alien

    devenv
    mysql-workbench
    gnome-keyring

    # Random GUI stuff
    feh
    obsidian # /shrug
    pandoc
    warpinator
    grimblast
    appimage-run
    nemo

    heroic-unwrapped

    vesktop

    revolt-desktop

    # Art?
    obs-studio

    # compressed stuff
    xarchiver
    unar
    unzip
    zip
    p7zip

    # Game stuff

    xonotic-sdl
    alvr

    # Emulation {
    retroarchFull
    pcsx2
    flycast
    ppsspp
    # torzu # I will not forget you.
    # }

    logmein-hamachi # my beloved
    parsec-bin # actual black magic.
    protontricks
    gamemode
    mangohud

    # Piracy stuff :)
    aria2

    # Music stuff
    nicotine-plus
    picard
    mpv
    # tauon # The best music player to ever exist, and it's broken rn FIXME

    # Music making

    AMB-plugins
    aether-lv2
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
    plugdata
    quadrafuzz
    samplv1
    sfizz
    sorcer
    surge-XT
    synthv1
    tap-plugins
    vital
    x42-plugins
    zam-plugins
    zita-at1
    zynaddsubfx

    rubberband

    # Misc
    btrfs-progs # btrfs my beloved
    rofi-power-menu
    rofi-pulse-select
  ];
}
