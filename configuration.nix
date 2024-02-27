# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Make some extra kernel modules available to NixOS
  #boot.extraModulePackages = [
  #    config.boot.kernelPackages.v4l2loopback
  #];
  # Set swappiness
  #boot.kernel.sysctl = { "vm.swappiness" = 200;};
    
  nixpkgs.config.allowUnfree = true;

  # Enable "experimental" features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ratholomew"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Buenos_Aires";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };


  fonts.packages = [ pkgs.fira-code-nerdfont ];

  
  programs = {
    droidcam = {
      enable = true;
    };
    dconf = {
      enable = true;
    };
  };

  # I love zram.
  zramSwap = {
    enable = true;
    memoryPercent = 75; # Give me all of it
  };

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  #services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware = {
    uinput.enable = true;
    pulseaudio.enable = true;
  };
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # This is needed for kmonad
  services.udev.extraRules = ''
  KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput
  '';

  qt.platformTheme = "qt5ct";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.theo = {
     isNormalUser = true;
     extraGroups = [ "wheel" "input" "uinput"]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
  #     xorg.xinit
  #     firefox
  #     tree
     ];
   };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

    haskellPackages.kmonad
    xorg.xev
    # Python stuff
    python3 python311Packages.pydbus
    python311Packages.pypresence

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

    # Music stuff
    nicotine-plus picard
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}

