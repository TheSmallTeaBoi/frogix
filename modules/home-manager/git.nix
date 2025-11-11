{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "theoiturri@tutanota.com";
        name = "TheSmallTeaBoi";
      };
      credential.helper = "store"; # Save credentials. This shit is unsafe af.
    };
  };
}
