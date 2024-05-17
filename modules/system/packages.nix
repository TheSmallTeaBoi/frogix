{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    haskellPackages.kmonad
    xorg.xev

    xclip

    # let's give this one last try...
    puredata
    zexy
    carla
    audacity
    bespokesynth

    btrfs-progs # btrfs my beloved
    gparted

    # Ricing stuff
    fira-code-nerdfont
    lxappearance
    catppuccin-papirus-folders
    qt5ct

    vim
    neofetch
    polybar
    rofi
    feh
    ripgrep
    jetbrains.pycharm-community-bin
    wget
    micro
    git
    fira-code-nerdfont
    fzf
    xfce.thunar
    xfce.tumbler
    gnome.gvfs
    pulsemixer
    bottom
    eza
    maim
    xdotool
    file
    yt-dlp
    ffmpeg
    appimage-run

    # compressed stuff
    unar
    unzip
    zip
    p7zip

    cinnamon.warpinator

    firefox
    w3m
    armcord
    krita
    discord-screenaudio # I was forced, mkey?
    obs-studio
    simplescreenrecorder
    darktable

    # Game stuff
    retroarchFull # Emulation stuff
    pcsx2
    flycast
    dolphinEmu
    rpcs3 # ^^^^^^^^^^^^^^^
    ppsspp # ^^^^^^^^^^^^^^^
    logmein-hamachi # my beloved
    protontricks

    # Piracy stuff :)
    aria2
    transmission_4-gtk
    # Music stuff
    nicotine-plus
    picard
    mpv
    # The best music player to ever exist
    tauon
  ];
}
