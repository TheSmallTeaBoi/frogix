# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Enable "experimental" features
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.trusted-users = ["root" "@wheel"];

  # This could a default at this point lol.
  nix.optimise.automatic = true;

  networking.hostName = "ratholomew"; # Define your hostname.

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = ["theo"];

  time.timeZone = "America/Buenos_Aires";

  fonts.packages = with pkgs; [nerd-fonts.fira-code noto-fonts noto-fonts-lgc-plus google-fonts];

  # I love zram.
  zramSwap = {
    enable = true;
    memoryPercent = 75; # Give me all of it
    algorithm = "lz4";
  };

  # rtkit is optional but recommended
  security.rtkit.enable = true;

  hardware = {
    uinput.enable = true;
  };

  home-manager.backupFileExtension = "bk";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.theo = {
    isNormalUser = true;
    extraGroups = ["wheel" "input" "uinput" "audio"];
  };

  # Disable the firewall altogether.
  networking.firewall.enable = false;

  nixpkgs.config = {allowUnfree = true;};

  programs.java = {
    enable = true;
  };

  # Enable Theme
  environment.variables = {
    HYPRCURSOR_SIZE = "8";
    GTK_THEME = "catppuccin-mocha-teal-standard";
  };
  qt.enable = true;
  qt.platformTheme = "gtk2";
  qt.style = "gtk2";

  console = {
    earlySetup = true;
    colors = [
      "24273a"
      "ed8796"
      "a6da95"
      "eed49f"
      "8aadf4"
      "f5bde6"
      "8bd5ca"
      "cad3f5"
      "5b6078"
      "ed8796"
      "a6da95"
      "eed49f"
      "8aadf4"
      "f5bde6"
      "8bd5ca"
      "a5adcb"
    ];
  };

  # Override packages
  nixpkgs.config.packageOverrides = pkgs: {
    colloid-icon-theme = pkgs.colloid-icon-theme.override {colorVariants = ["teal"];};
    catppuccin-gtk = pkgs.catppuccin-gtk.override {
      accents = ["teal"];
      size = "standard";
      variant = "mocha";
    };
  };

  environment.systemPackages = with pkgs; [
    numix-icon-theme-circle
    colloid-icon-theme
    catppuccin-gtk
    catppuccin-kvantum
  ];

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
