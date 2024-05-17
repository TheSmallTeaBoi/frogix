{
  inputs,
  outputs,
  pkgs,
  config,
  ...
}: {
  programs.git = {
    enable = true;
    userEmail = "theoiturri@tutanota.com";
    userName = "TheSmallTeaBoi";
    extraConfig = {
      credential.helper = "cache --timeout=3600"; # Cache credentials for 1 hour
    };
  };
}
