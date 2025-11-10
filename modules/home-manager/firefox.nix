{
  pkgs,
  config,
  ...
}:
{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.tridactyl-native ];
    profiles.theo = {
      isDefault = true;
      extensions.force = true;
      settings = {
        # Enable userChrome customizations
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        # Disable translation popup
        "browser.translations.automaticallyPopup" = false;
        "browser.cache.disk.enable" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.visibility" = "always-show";
        "sidebar.revamp" = true;
        "sidebar.animation.expand-on-hover.duration-ms" = 50;
      };
    };
  };

  # Tridactyl config
  home.file.".config/tridactyl/tridactylrc" = {
    enable = true;
    text =
      #vim
      ''
        " Make sure we start from a clean state
        sanitise tridactyllocal

        " Binds
        bind g1 tab 1
        bind g3 tab 3
        bind g5 tab 5
        bind g7 tab 7
        bind g2 tab 2
        bind g4 tab 4
        bind g6 tab 6
        bind g8 tab 8
        bind g9 tab 9
        bind gt fillcmdline tab


        " Allow Ctrl-c to copy in the commandline
        unbind --mode=ex <C-c>

        " Open right click menu on links
        bind ;C composite hint_focus; !s xdotool key Menu

        " Binds for new reader mode
        bind gr reader
        bind gR reader --tab

        " Misc settings

        " Set colorscheme
        colors shydactyl

        " Sane hinting mode
        set hintfiltermode vimperator-reflow
        set hintnames short

        set editorcmd kitty --class floating -e $EDITOR

        " Defaults to 300ms but I'm a 'move fast and close the wrong tabs' kinda dude
        set hintdelay 200
        set hintchars srtnfgyeia
      '';
  };

  # Dark reader color config.
  xdg = {
    configFile = {
      # Creates a config for DarkReader
      # TODO, need to make this auto update?
      darkreader = {
        enable = true;
        #onChange = manually tell darkreader to refresh somehow?
        target = "darkreader/config.json";
        text = ''
          {
              "schemeVersion": 2,
              "enabled": true,
              "fetchNews": true,
              "theme": {
          	"mode": 1,
          	"brightness": 100,
          	"contrast": 100,
          	"grayscale": 0,
          	"sepia": 0,
          	"useFont": false,
          	"fontFamily": "Open Sans",
          	"textStroke": 0,
          	"engine": "dynamicTheme",
          	"stylesheet": "",
          	"darkSchemeBackgroundColor": "${config.lib.stylix.colors.withHashtag.base00}",
          	"darkSchemeTextColor": "${config.lib.stylix.colors.withHashtag.base05}",
          	"lightSchemeBackgroundColor": "${config.lib.stylix.colors.withHashtag.base05}",
          	"lightSchemeTextColor": "${config.lib.stylix.colors.withHashtag.base00}",
          	"scrollbarColor": "auto",
          	"selectionColor": "auto",
          	"styleSystemControls": false,
          	"lightColorScheme": "Default",
          	"darkColorScheme": "Default",
          	"immediateModify": false
              },
              "presets": [],
              "customThemes": [],
              "enabledByDefault": true,
              "enabledFor": [],
              "disabledFor": [],
              "changeBrowserTheme": false,
              "syncSettings": false,
              "syncSitesFixes": true,
              "automation": {
          	"enabled": false,
          	"mode": "",
          	"behavior": "OnOff"
              },
              "time": {
          	"activation": "18:00",
          	"deactivation": "9:00"
              },
              "location": {
          	"latitude": null,
          	"longitude": null
              },
              "previewNewDesign": true,
              "enableForPDF": true,
              "enableForProtectedPages": true,
              "enableContextMenus": false,
              "detectDarkTheme": false,
              "displayedNews": [
          	"thanks-2023"
              ]
          }

        '';
      };
    };
  };
}
