{ ... }:
{
  programs.vesktop = {
    enable = true;
    settings = {
      discordBranch = "ptb";
      tray = false;
      minimizeToTray = false;
      hardwareVideoAcceleration = true;
      disableMinSize = true;
      arRPC = true;
      enabledThemes = [ "stylix.css custom.css" ];
    };
  };
  xdg.configFile."vesktop/themes/custom.css".text =
    # css
    ''
      /* Dubyas list of annoying stuff he hides in discord using Quick CSS */
      @import url("https://raw.githubusercontent.com/DubyaDude/DubyasCleanupOfDiscord/main/DubyasCleanupOfDiscord.css");

      /* Disables the dumb top bar */
      div [class="bar_c38106"]
      {
        display: none;
      }
      :root
      {
        --custom-app-top-bar-height: 0px;
      }

      /* Add 12px offset to the server list, fixes the uncomfortable look when removing the titlebar*/
      nav.wrapper_ef3116 {
        padding-top: 12px;
      }
    '';
}
