{
  pkgs,
  inputs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Ricing stuff
    pywal16
    psmisc
    waybar-mpris
    mako
    rofi

    # Terminal tools
    clipse
    wl-clipboard
    wtype
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
    ranger # Mostly for qutebrowser to be honest.
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
    bubblewrap
    opencode

    vial

    # Coding, I guess
    inputs.nix-alien.packages.x86_64-linux.nix-alien
    # inputs.hermes-agent.packages.x86_64-linux.desktop # BROKEN UPSTREAM 2026-09-07: node headers hash mismatch, see hermes-agent#61443/#72095

    devenv
    gnome-keyring

    (tic-80.override { withPro = true; }) # :3

    # Random GUI stuff
    feh
    obsidian # Moving to org, keeping it for older notes, just for some time.
    pandoc
    warpinator
    grimblast
    appimage-run
    nemo
    calibre

    xwayland-satellite

    heroic-unwrapped

    # Art?
    obs-studio

    # compressed stuff
    unar
    p7zip

    # Game stuff

    lsfg-vk
    lsfg-vk-ui
    steamtinkerlaunch
    gpu-screen-recorder-gtk

    (prismlauncher.override {
      jdks = with pkgs; [
        jdk21
      ];
    })

    beammp-launcher

    # Emulation {
    # retroarch-full
    pcsx2
    # torzu # I will not forget you.
    # }

    logmein-hamachi # my beloved
    parsec-bin # actual black magic.
    protontricks
    mangohud

    # Piracy stuff :)
    aria2
    stremio-linux-shell

    # Music stuff
    nicotine-plus
    picard
    mpv
    feishin

    # Music making
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
