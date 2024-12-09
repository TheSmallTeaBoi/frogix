{pkgs, ...}: {
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [pkgs.tridactyl-native];
    profiles.theo = {
      isDefault = true;
      userChrome =
        #css
        ''
          @import "${
            builtins.fetchGit {
              url = "https://github.com/rockofox/firefox-minima";
              ref = "main";
              rev = "c5580fd04e9b198320f79d441c78a641517d7af5";
            }
          }/userChrome.css";

          .tabbrowser-tab:first-child{ counter-reset: nth-tab 0 } /* Change to -1 for 0-indexing */
          .tab-text::before{ content: counter(nth-tab) " | "; counter-increment: nth-tab }

          .tabbrowser-tab .tab-label
          {
          font-family: FiraCode Nerd Font Mono !important;
          font-size: 14px !important;
          }
        '';
      settings = {
        # Enable userChrome customizations
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        # Disable translation popup
        "browser.translations.automaticallyPopup" = false;
      };
    };
  };

  # Tridactyl config
  xdg.configFile.".tridactylrc".text =
    #vim
    ''

      " Make sure we start from a clean state
      sanitise tridactyllocal

      " Set newtab to my dashboard
      set newtab home.iturriflix.local

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

      " Comment toggler for Reddit, Hacker News and Lobste.rs
      bind ;c hint -Jc [class*="expand"],[class*="togg"],[class="comment_folder"]

      " make t open the selection with tabopen
      bind --mode=visual t composite js document.getSelection().toString() | fillcmdline tabopen

      " Make gu take you back to subreddit from comments
      bindurl reddit.com gu urlparent 4

      " Make `gi` on GitHub take you to the search box
      bindurl ^https://github.com gi hint -Vc .AppHeader-searchButton

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

      " Defaults to 300ms but I'm a 'move fast and close the wrong tabs' kinda chap
      set hintdelay 200
      set hintchars srtnfgyeia
    '';
}
