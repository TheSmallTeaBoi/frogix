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

    # Coding, I guess
    inputs.self.packages.x86_64-linux.neovim
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

    armcord
    discord-screenaudio # I was forced, mkey?

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
    superTuxKart
    # Emulation {
    retroarchFull
    pcsx2
    flycast
    ppsspp
    # }

    logmein-hamachi # my beloved
    protontricks

    # Piracy stuff :)
    aria2

    # Music stuff
    nicotine-plus
    picard
    mpv
    tauon # The best music player to ever exist

    # Misc
    haskellPackages.kmonad
    btrfs-progs # btrfs my beloved
    rofi-power-menu
    rofi-pulse-select
  ];
}
