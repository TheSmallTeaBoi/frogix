{...}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "theoiturri@tutanota.com";
        name = "TheSmallTeaBoi";
      };
      credential.helper = "cache --timeout=3600"; # Cache credentials for one hour
    };
  };
}
