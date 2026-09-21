{ config, pkgs, lib, ... }:
# qute-adblock — declarative qutebrowser adblocking.
# qute has no native cosmetic filtering, so this compiles upstream filter
# lists (git-pinned easylist/easylist, see ./bundle.nix) into two layers:
#   1. cosmetic.css — generic `##selector` hiding, via user_stylesheets
#   2. domain-scoped `domain##selector` + `#@#` exceptions, spliced into the
#      userscript and applied per-hostname at document-start
# plus the native network blocker maxed out + general userscript.
# updates: ./update-qute-lists.sh (bumps the rev, commit the diff).
let
  adblockBundle = import ./bundle.nix { inherit pkgs lib; };
in
{
  programs.qutebrowser.settings = {
    content.blocking.method = lib.mkDefault "both";
    content.blocking.adblock.lists = lib.mkDefault [
      "https://easylist.to/easylist/easylist.txt"
      "https://easylist.to/easylist/easyprivacy.txt"
      "https://secure.fanboy.co.nz/fanboy-annoyance.txt"
      "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt"
      "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt"
      "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt"
      "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt"
      "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt"
      "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=0&mimetype=plaintext"
    ];
    content.javascript.can_open_tabs_automatically = lib.mkDefault false;
    content.user_stylesheets = [ "${adblockBundle}/share/qutebrowser/cosmetic.css" ];
  };

  # same convention as sponsorblock.js in browser.nix
  xdg.configFile."qutebrowser/greasemonkey/qute-goop-remover.user.js".source =
    "${adblockBundle}/share/qutebrowser/greasemonkey/qute-goop-remover.user.js";
}
