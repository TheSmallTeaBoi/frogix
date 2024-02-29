{pkgs, ...}:
{
  environment.systemPackages = with pkgs; [

    haskellPackages.kmonad
    xorg.xev

    xclip

    # The best music player to ever exist
    tauon

    # Ricing stuff
    fira-code-nerdfont lxappearance catppuccin-papirus-folders
    qt5ct

    vim neofetch polybar rofi feh
    wget micro
    git fira-code-nerdfont fzf
    firefox flameshot xfce.thunar xfce.tumbler
    armcord
    pulsemixer bottom
    eza maim xdotool
    yt-dlp
    marktext
    appimage-run

    unar
    cinnamon.warpinator
    pcsx2

    # Music stuff
    nicotine-plus picard
  ];
}
