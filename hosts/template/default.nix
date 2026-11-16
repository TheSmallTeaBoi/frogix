{ ... }:
# realistic desktop starting point: universal defaults are ON (nvidia + sddm +
# niri session, the full rice, gaming, packages). copy this folder to
# hosts/<name>, replace hardware-configuration.nix with your
# nixos-generate-config output, fill in the TODOs, `git add`, rebuild.
{
  imports = [
    ./hardware-configuration.nix   # TODO: replace with your nixos-generate-config output
    ../../modules
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "template";  # TODO: your hostname

  # the release this machine was FIRST installed on — never bump it afterwards.
  # ratholomew says 23.11 because that is when it was installed; new installs
  # say the current release (26.11 today).
  system.stateVersion = "26.11";

  frogix = {
    enable = true;
    user = "you";  # TODO: your username

    # nixpkgs currently marks the pinned qutebrowser insecure; drop the entry
    # once your channel moves past it
    nix.permittedInsecurePackages = [ "qutebrowser-3.7.0" ];

    # defaults are opt-out: uncomment what this machine does NOT have.
    # disabling `gaming` also drops "gamemode" from users.extraGroups.
    # steam.enable = false;
    # wine.enable = false;
    # gaming.enable = false;
    # virt.enable = false;
    # droidcam.enable = false;
    # musicMaking.enable = false;    # realtime audio tweaks + the plugin rack
    # "emeet-linux".enable = false;
    # "xodus-nexus".enable = false;
    # (torbox / "torbox-music-sync" are default-off opt-ins; they need sops
    #  secrets, so turn them on together with sops below)

    # services (navidrome/syncthing/...) and romm read sops secrets, so these
    # three travel together: all on once your age key lives at
    # ~/.config/sops/age/keys.txt and modules/system/secrets/secrets.yaml is
    # decryptable by it — all off until then.
    services.enable = false;
    romm.enable = false;
    sops.enable = false;
  };

  # first login needs a password; `passwd` after booting, then delete this line
  users.users.you.initialPassword = "changeme";

  home-manager.users.you = {
    frogix.home.stateVersion = "26.11";  # same rule as system.stateVersion

    # niri/pywal/hypridle need at least the main monitor name (`niri msg
    # outputs` lists them); rules referencing an unset screen are omitted.
    # hosts/ratholomew/configuration.nix has a full three-screen example.
    frogix.screens.main = "DP-1";  # TODO: your main monitor (required — see /sys/class/drm/*/status for names)
    # frogix.screens.left = "HDMI-A-1";
    # frogix.screens.right = "HDMI-A-3";

    # identity knobs — null means the feature writes nothing:
    # frogix.git = { email = "you@example.com"; name = "You"; };
    # frogix.iamb.matrixId = "@you:matrix.org";
  };
}
