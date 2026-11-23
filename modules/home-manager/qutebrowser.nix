{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.qutebrowser;
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
  options.frogix.qutebrowser.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "qutebrowser with the pywal rice: pywalQute colors, ricecdp live light/dark, containers, sponsorblock";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."qutebrowser/pywalQute".source = pywalQute;

    # live light/dark for websites over the devtools protocol (see the module's
    # docstring; needs QTWEBENGINE_REMOTE_DEBUGGING, set on the niri spawn line)
    xdg.configFile."qutebrowser/ricecdp.py".source = ./qute-rice/ricecdp.py;
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

    # the config file that defines CONTAINER_LIST, CONTAINER_BASE and helper funcs
    xdg.dataFile."qutebrowser/userscripts/containers_config".source =
      "${qute-containers}/containers_config";

    programs.qutebrowser = {
      enable = true;
      settings = {
        hints.chars = "strdnaei";
        scrolling.smooth = true;

        tabs.show = "multiple";
        # (no custom adblock userscript — see content.blocking below)

        colors.webpage = {
          # startup default only — extraConfig below re-sets this from
          # ~/.config/rice/mode on every start / :config-source.
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

          # native adblocking only (qutebrowser's Brave ABP engine + hosts
          # files). this replaced the custom qute-adblock userscript engine:
          # its hand-rolled full-document reflow sweeps pinned the main thread
          # on large SPAs (reddit, ddg search), so it was removed entirely.
          blocking = {
            method = lib.mkDefault "both";
            adblock.lists = lib.mkDefault [
              "https://easylist.to/easylist/easylist.txt"
              "https://easylist.to/easylist/easyprivacy.txt"
              "https://secure.fanboy.co.nz/fanboy-annoyance.txt"
              "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt"
              "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt"
              "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt"
              "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt"
              "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt"
              "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=0&mimetype=plaintext"
              "https://raw.githubusercontent.com/easylist/easylist/master/easylist_adult/adult_adservers.txt"
              "https://raw.githubusercontent.com/easylist/easylist/master/easylist_adult/adult_thirdparty.txt"
              "https://raw.githubusercontent.com/easylist/easylist/master/easylist_adult/adult_adservers_popup.txt"
              "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2024.txt"
              "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2025.txt"
              "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2026.txt"
              "https://raw.githubusercontent.com/gioxx/xfiles/master/filtri.txt"
              "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/AnnoyancesList"
              "https://filters.adtidy.org/windows/filters/2.txt"
            ];
          };
          javascript.can_open_tabs_automatically = lib.mkDefault false;
        };

        editor.command = [
          "emacsclient"
          "-c"
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

          # Two browser windows, one per screen
          " bt" = "cmd-set-text -s :tab-take";

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
          import os

          # rice mode (see pywal.nix). chrome colors follow the pywal cache on
          # their own; websites need this explicit opt-in. RESTART-ONLY:
          # qutebrowser hands preferredColorScheme to QtWebEngine as a blink
          # setting at startup (configdata.yml: `restart: true`), so `rice-mode`
          # restarts the browser after flipping the mode file.
          mode_path = os.path.expanduser('~/.config/rice/mode')
          try:
              with open(mode_path) as f:
                  rice_mode = f.read().strip()
          except OSError:
              rice_mode = 'dark'
          if rice_mode != 'light':
              rice_mode = 'dark'

          config.set('colors.webpage.preferred_color_scheme', rice_mode)

          # and push it to the live pages: preferred_color_scheme is a startup-only
          # blink flag, ricecdp flips the media feature over devtools instead.
          import ricecdp
          ricecdp.apply()
          config.set('colors.webpage.darkmode.enabled', rice_mode == 'dark', 'qute://*')
          config.set('colors.webpage.darkmode.enabled', rice_mode == 'dark',
                     'www.w3schools.com')
        ''
        + lib.optionalString config.frogix.pywal.enable ''

          import pywalQute.draw
          if os.path.exists('${config.home.homeDirectory}/.cache/wal/colors.json'):
              pywalQute.draw.color(c, {
                  'spacing': {
                      'vertical': 6,
                      'horizontal': 8
                  }
              })
        ''
        + ''

          c.content.javascript.log_message.excludes = {
            'userscript:_qute_stylesheet' : ['*Refused to apply inline style   because it violates the following Content Security Policy directive:   *'],
            'userscript:_qute_js' : ['*TrustedHTML*']
          }
        '';
    };
  };
}
