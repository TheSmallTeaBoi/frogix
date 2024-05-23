{
  config,
  pkgs,
  inputs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # let's give this one last try... (Music)
    puredata
    zexy
    carla
    audacity
    bespokesynth

    # Ricing stuff
    fira-code-nerdfont
    lxappearance
    catppuccin-papirus-folders
    qt5ct
    polybar
    rofi

    # Terminal tools
    fzf
    ripgrep
    neofetch
    wget
    git
    pulsemixer
    bottom
    eza
    file
    yt-dlp
    ffmpeg
    iamb

    # Coding, I guess
    inputs.self.packages.x86_64-linux.neovim
    jetbrains.pycharm-community-bin

    # Random GUI stuff
    firefox
    feh
    xfce.thunar
    xfce.tumbler
    gnome.gvfs
    cinnamon.warpinator
    maim
    xdotool
    appimage-run
    xorg.xev
    xclip
    gparted

    armcord
    discord-screenaudio # I was forced, mkey?

    # Art?
    krita
    obs-studio
    simplescreenrecorder
    darktable

    # compressed stuff
    unar
    unzip
    zip
    p7zip

    # Game stuff
    # Emulation {
    retroarchFull # Emulation stuff
    pcsx2
    flycast
    dolphinEmu
    rpcs3
    ppsspp
    # }

    logmein-hamachi # my beloved
    protontricks

    # Piracy stuff :)
    aria2
    transmission_4-gtk

    # Music stuff
    nicotine-plus
    picard
    mpv
    tauon # The best music player to ever exist

    # Misc
    haskellPackages.kmonad
    btrfs-progs # btrfs my beloved
  ];
}
