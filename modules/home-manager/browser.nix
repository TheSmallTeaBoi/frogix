{
  pkgs,
  config,
  ...
}:
let
  pywalQute = pkgs.fetchFromGitHub {
    owner = "makman12";
    repo = "pywalQute";
    rev = "main";
    sha256 = "sha256-hTVhVdn3OMG+mLE87/dopANIEZ3laRPoys/dOTbBsZM=";
  };

  qute-containers = pkgs.fetchFromGitHub {
    owner = "s-praveen-kumar";
    repo = "qute-containers";
    rev = "main";
    sha256 = "sha256-g684sPSEJTRSk2V8LVrQsNeRIYtaQueRpZeREWtmQKw=";
  };

  sponsorblock = pkgs.fetchurl {
    url = "https://git.gymnasium-hummelsbuettel.de/MZ/qutebrowser-greasemonkey/-/raw/main/youtube_sponsorblock.js?ref_type=heads";
    sha256 = "sha256-cSoHh6/4h+V494WSi8dhXk0T3BKuiwOG/QoluCYhb4k=";
  };
in
{
  xdg.configFile."qutebrowser/pywalQute".source = pywalQute;
  xdg.configFile."qutebrowser/greasemonkey/sponsorblock.js".source = sponsorblock;

  xdg.dataFile = {
    "qutebrowser/userscripts/container-open" = {
      source = "${qute-containers}/container-open";
      executable = true;
    };
    "qutebrowser/userscripts/container-add" = {
      source = "${qute-containers}/container-add";
      executable = true;
    };
    "qutebrowser/userscripts/container-rm" = {
      source = "${qute-containers}/container-rm";
      executable = true;
    };
    "qutebrowser/userscripts/container-ls" = {
      source = "${qute-containers}/container-ls";
      executable = true;
    };
  };

  # the config file that defines CONTAINER_LIST and CONTAINER_BASE
  xdg.dataFile."qutebrowser/userscripts/containers_config".text = ''
    CONTAINER_LIST="$HOME/.config/qute-containers/containers"
    CONTAINER_BASE="$HOME/.local/share/qute-containers"
  '';

  xdg.dataFile."qutebrowser/userscripts/containers_config".source =
    "${qute-containers}/containers_config";

  programs.qutebrowser = {
    enable = true;
    settings = {
      hints.chars = "strdnaei";
      scrolling.smooth = true;

      tabs.show = "multiple";

      colors.webpage = {
        preferred_color_scheme = "dark";
        darkmode.enabled = false;
        darkmode.algorithm = "lightness-cielab";
      };

      statusbar.show = "in-mode";

      session.lazy_restore = false;
      auto_save.session = true;

      content = {
        pdfjs = true;
        persistent_storage = true;
      };

      editor.command = [
        "emacs"
        "{file}"
      ];

    };
    keyBindings = {
      normal = {
        # Open bitwarden in this website
        " p" = "open -t https://vault.bitwarden.com/#/vault?search={url:host}";

        # Easier for me than the uppercase letters
        " h" = "back";
        " l" = "forward";

        # "Toggle"
        " tr" = "spawn --userscript readability";
        " td" = "config-cycle colors.webpage.darkmode.enabled true false";

        # Tabs
        " 1" = "tab-focus 1";
        " 2" = "tab-focus 2";
        " 3" = "tab-focus 3";
        " 4" = "tab-focus 4";
        " 5" = "tab-focus 5";
        " 6" = "tab-focus 6";
        " 7" = "tab-focus 7";
        " 8" = "tab-focus 8";
        " 9" = "tab-focus 9";
        " `" = "tab-focus last";

        # "Buffer"
        " bd" = "tab-close";
        " bD" = "tab-only";
        " bn" = "tab-next";
        " bp" = "tab-prev";
        " bm" = "tab-move";
        " bb" = "tab-select";

        # Containers
        " co" = "spawn --userscript container-open";
        " ca" = "cmd-set-text -s :spawn --userscript container-add";
        " cd" = "cmd-set-text -s :spawn --userscript container-rm";
        " cl" = "spawn --userscript container-ls";
        " cf" = "hint links userscript container-open";

        # MPV
        " mo" = "spawn mpv --force-window=immediate {url}";
        " mf" = "hint links mpv --force-window=immediate {url}";

      };
    };

    quickmarks = {
      # Social
      whatsapp = "https://web.whatsapp.com/";
      element = "https://app.element.io";
      telegram = "https://web.telegram.org";
      reddit = "https://reddit.com";

      # Entertainment
      youtube = "https://youtube.com";
      ytm = "https://music.youtube.com";
      twitch = "https://twitch.tv";
      netflix = "https://netflix.com";

      # Piracy & media
      torbox = "https://torbox.app";
      archive = "https://archive.org";
      annas = "https://shadowlibraries.github.io/DirectDownloads/AnnasArchive";
      fmhy = "fmhy.net";
      bunkr = "https://balbums.st";

      # Development
      github = "https://github.com";
      gitlab = "https://gitlab.com";

      # AI
      aistudio = "https://aistudio.google.com";
      claude = "https://claude.ai";
      chatgpt = "https://chatgpt.com";
      deepseek = "https://chat.deepseek.com";

      # Productivity
      gmail = "https://mail.google.com";
      drive = "https://drive.google.com";
      translate = "https://translate.google.com";
      linguee = "https://www.linguee.com";

      # Others
      marketplace = "https://www.facebook.com/marketplace";
    };

    searchEngines = {
      # General
      g = "https://www.google.com/search?hl=en&q={}";
      ddg = "https://duckduckgo.com/?q={}";
      so = "https://stackoverflow.com/search?q={}";
      r = "https://www.reddit.com/search/?q={}";
      yt = "https://www.youtube.com/results?search_query={}";

      # Wikipedia
      w = "https://en.wikipedia.org/wiki/Special:Search?search={}&go=Go&ns0=1";
      ws = "https://es.wikipedia.org/wiki/Special:Search?search={}&go=Go&ns0=1";

      # Arch / Nix
      aw = "https://wiki.archlinux.org/?search={}";
      nw = "https://wiki.nixos.org/index.php?search={}";
      no = "https://search.nixos.org/options?query={}";
      np = "https://search.nixos.org/packages?query={}";
      hm = "https://home-manager-options.extranix.com/?query={}";
      nh = "https://mynixos.com/search?q={}";

      # Development
      gh = "https://github.com/search?q={}";
      gl = "https://gitlab.com/search?search={}";

      # Documentation
      mdn = "https://developer.mozilla.org/en-US/search?q={}";
      rs = "https://docs.rs/releases/search?query={}";
      npm = "https://www.npmjs.com/search?q={}";
    };

    perDomainSettings = {
      # Otherwise google doesn't let you sign in because "insecure"
      "https://accounts.google.com/*".content.headers.user_agent =
        "Mozilla/5.0 ({os_info}; rv:135.0) Gecko/20100101 Firefox/135";

      # Enable the darkmode thing for some pages I use the most.
      "qute://*".colors.webpage.darkmode.enabled = true;
      "www.w3schools.com".colors.webpage.darkmode.enabled = true;
    };

    extraConfig =
      #python
      ''
        import pywalQute.draw
        import json

        pywalQute.draw.color(c, {
            'spacing': {
                'vertical': 6,
                'horizontal': 8
            }
        })


        with open('/home/theo/.cache/wal/colors.json') as f:
            wal = json.load(f)

        bg = wal['special']['background']
        fg = wal['special']['foreground']

        c.content.javascript.log_message.excludes = {
          'userscript:_qute_stylesheet' : ['*Refused to apply inline style   because it violates the following Content Security Policy directive:   *'],
          'userscript:_qute_js' : ['*TrustedHTML*']
        }

      '';
  };

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [
      pkgs.tridactyl-native
      pkgs.pywalfox-native
    ];
    configPath = "${config.home.homeDirectory}/.mozilla/firefox";
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

}
