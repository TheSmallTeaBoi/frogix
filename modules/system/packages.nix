{pkgs, ...}:
{
  environment.systemPackages = with pkgs; [

    haskellPackages.kmonad
    xorg.xev

    xclip

    btrfs-progs # btrfs my beloved
    gparted

    # Diablo 2 stuff :3
    xdelta jq gnome.zenity wmctrl libnotify

    # Ricing stuff
    fira-code-nerdfont lxappearance catppuccin-papirus-folders
    qt5ct


    vim neofetch polybar rofi feh
    wget micro
    git fira-code-nerdfont fzf
    xfce.thunar xfce.tumbler gnome.gvfs
    pulsemixer bottom
    eza maim xdotool file
    yt-dlp ffmpeg
    marktext
    appimage-run

    # compressed stuff
    unar unzip zip p7zip

    cinnamon.warpinator

    firefox w3m armcord gomuks cinny-desktop /* krita */
    discord-screenaudio # I was forced, mkey?
    obs-studio simplescreenrecorder vokoscreen

    # Game stuff
    retroarchFull                  # Emulation stuff
    pcsx2 flycast dolphinEmu rpcs3 # ^^^^^^^^^^^^^^^
    logmein-hamachi # my beloved
    protontricks

    # Piracy stuff :)
    aria2 transmission_4-gtk
    # Music stuff
    nicotine-plus picard
    mpv
    # The best music player to ever exist
    tauon

  ];
}
