{ ... }:
{
  services.mako = {
    enable = true;
    settings = {
      backgroundColor = "#1e1e2e";
      textColor = "#cdd6f4";
      borderRadius = 5;
      borderColor = "#cdd6f4";
      margin = "20";
      # defaultTimeout = 5;
      extraConfig = ''
        border-size=3
      '';
    };
  };
}
