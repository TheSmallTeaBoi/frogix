{
  pkgs,
  inputs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Ricing stuff
    fira-code-nerdfont
    catppuccin-papirus-folders
    polybar
    rofi

    # Terminal tools
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
    yt-dlp
    ffmpeg
    iamb
    qmk
    qmk-udev-rules
    playerctl
    picotts

    vial

    # Coding, I guess
    inputs.self.packages.x86_64-linux.neovim
    inputs.nix-alien.packages.x86_64-linux.nix-alien
    vim
    vimgolf
    devenv

    # Random GUI stuff
    feh
    obsidian # /shrug
    pandoc
    cinnamon.warpinator
    scrot
    maim
    autorandr # Multiple screens suck, man
    xdotool
    appimage-run
    xclip

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
    openjdk22
    # Emulation {
    retroarchFull
    pcsx2
    flycast
    ppsspp
    # }

    logmein-hamachi # my beloved
    parsec-bin # actual black magic.
    protontricks

    # Piracy stuff :)
    aria2

    # Music stuff
    nicotine-plus
    picard
    mpv
    tauon # The best music player to ever exist

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
    distrho
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

    # Misc
    # haskellPackages.kmonad
    btrfs-progs # btrfs my beloved
    rofi-power-menu
    rofi-pulse-select
  ];
}
