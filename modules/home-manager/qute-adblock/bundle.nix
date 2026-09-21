{ pkgs, lib }:
# qute-adblock bundle — compiles upstream filter lists (git-pinned
# easylist/easylist) into cosmetic.css + userscript with spliced site data.
# built by default.nix; test directly with:
#   nix-build -E 'with import <nixpkgs> {}; import ./bundle.nix { inherit pkgs lib; }'
let
  filterLists = pkgs.fetchFromGitHub {
    owner = "easylist";
    repo = "easylist";
    rev = "1907d2bda03fc98e0f376a00652918ab11ad6419";
    hash = "sha256-L0eXno7mUZ3EwlF1qecSw0ivDvtj1bkJQA7zbmpy3z8=";
  };
  genericSrcs = [
    "easylist/easylist_general_hide.txt"
    "easylist_cookie/easylist_cookie_general_hide.txt"
    "fanboy-addon/fanboy_annoyance_general_hide.txt"
    "fanboy-addon/fanboy_social_general_hide.txt"
    "fanboy-addon/fanboy_newsletter_general_hide.txt"
    "fanboy-addon/fanboy_notifications_general_hide.txt"
  ];
  # specific_hide (+abp/ubo/international/adult variants): plain `##` rules in
  # these files work as native css in chromium (incl. :has()); procedural ops
  # (:contains, :matches-, :xpath, :style(), +js) are filtered out below.
  scopedSrcs = [
    "easylist/easylist_specific_hide.txt"
    "easylist/easylist_specific_hide_abp.txt"
    "easylist_cookie/easylist_cookie_specific_hide.txt"
    "easylist_cookie/easylist_cookie_specific_ABP.txt"
    "easylist_cookie/easylist_cookie_specific_uBO.txt"
    "easylist_cookie/easylist_cookie_international_specific_hide.txt"
    "fanboy-addon/fanboy_annoyance_specific_hide.txt"
    "fanboy-addon/fanboy_annoyance_specific_ABP.txt"
    "fanboy-addon/fanboy_annoyance_specific_uBO.txt"
    "fanboy-addon/fanboy_annoyance_international.txt"
    "fanboy-addon/fanboy_social_specific_hide.txt"
    "fanboy-addon/fanboy_social_specific_ABP.txt"
    "fanboy-addon/fanboy_social_specific_uBO.txt"
    "fanboy-addon/fanboy_social_international.txt"
    "fanboy-addon/fanboy_newsletter_specific_hide.txt"
    "fanboy-addon/fanboy_newsletter_specific_ABP.txt"
    "fanboy-addon/fanboy_newsletter_specific_uBO.txt"
    "fanboy-addon/fanboy_notifications_specific_hide.txt"
    "fanboy-addon/fanboy_notifications_specific_ABP.txt"
    "fanboy-addon/fanboy_notifications_specific_uBO.txt"
    "easylist_adult/adult_specific_hide.txt"
  ];
in
  pkgs.stdenvNoCC.mkDerivation {
    name = "qute-adblock-bundle";
    src = filterLists;
    userScript = ./qute-goop-remover.user.js;
    unpackPhase = "true";
    buildPhase = ''
      # fail loudly on a 404'd component instead of shipping empty lists.
      # (note: $src is the read-only store; outputs go to the build dir.)
      for f in ${lib.concatStringsSep " " (genericSrcs ++ scopedSrcs)}; do
        test -f "$src/$f" || { echo "missing component: $f" >&2; exit 1; }
      done
      css_filter() {
        grep -v '^!' | grep -v '^$' \
        | grep -v ':contains\|:matches\|:xpath\|:style\|:remove\|+js\|:if\|:watch-attr\|:upward\|:nth-ancestor\|:other(' \
        | grep -v '\[\[\|\]\]'
      }
      # 1. generic hiding -> cosmetic.css (400 selectors per rule)
      cat ${lib.concatMapStringsSep " " (f: "\"${filterLists}/${f}\"") genericSrcs} \
        | grep '^##' | sed 's/^##//' | css_filter \
        | LC_ALL=C sort -u > selectors.txt
      awk 'BEGIN{n=0} {buf[n++]=$0; if(n==400){for(j=0;j<n;j++){printf "%s%s", buf[j], (j<n-1?",\n":"")}; print "\n{display:none !important;}\n"; n=0}} END{if(n>0){for(j=0;j<n;j++){printf "%s%s", buf[j], (j<n-1?",\n":"")}; print "\n{display:none !important;}\n"}}' \
        selectors.txt > cosmetic.css
      # 2. domain-scoped hiding + exceptions -> site-data.js.
      # skips: comments, ~negations, entity wildcards, multi-## lines.
      cat ${lib.concatMapStringsSep " " (f: "\"${filterLists}/${f}\"") scopedSrcs} \
        | grep '##' | grep -v '^##' | grep -v '^!' | grep -v '#@#\|#?#\|#+js\|\$#' \
        | css_filter \
        | awk -F'##' 'NF==2 && $1 !~ /[#?*$^\/~[]/ && $2 !~ /^\s*$/ {print $1"##"$2}' \
        | LC_ALL=C sort -u > scoped.txt
      cat ${lib.concatMapStringsSep " " (f: "\"${filterLists}/${f}\"") scopedSrcs} \
        | grep '#@#' | grep -v '^!' | grep -v '#?#\|#+js' \
        | awk -F'#@#' 'NF==2 && $1 !~ /[#?*$^\/~[]/ {print $1"#@#"$2}' \
        | LC_ALL=C sort -u > unhide.txt
      awk -F'##' '{ n=split($1,ds,",");
        sel=$2; gsub(/\\/,"\\\\",sel); gsub(/"/,"\\\"",sel);
        for(i=1;i<=n;i++){ d=ds[i]; if(d=="") continue;
          if(!(d in seen)){ domains[++nd]=d; seen[d]=1; }
          css[d]=css[d] (css[d]?",":"") "\"" sel "\""; } }
        END{ printf "var SITE_CSS_DATA={";
          for(i=1;i<=nd;i++){ d=domains[i];
            printf "%s\"%s\":[%s]",(i>1?",":""),d,css[d]; }
          print "};" }' scoped.txt > site-css.js
      awk -F'#@#' '{ n=split($1,ds,",");
        sel=$2; gsub(/\\/,"\\\\",sel); gsub(/"/,"\\\"",sel);
        for(i=1;i<=n;i++){ d=ds[i]; k=(d==""?"*":d);
          if(!(k in seen)){ domains[++nd]=k; seen[k]=1; }
          css[k]=css[k] (css[k]?",":"") "\"" sel "\""; } }
        END{ printf "var SITE_UNHIDE_DATA={";
          for(i=1;i<=nd;i++){ d=domains[i];
            printf "%s\"%s\":[%s]",(i>1?",":""),d,css[d]; }
          print "};" }' unhide.txt > site-unhide.js
      cat site-css.js site-unhide.js > site-data.js
      # 3. splice data into the userscript at //__SITE_DATA__
      sed '/^\/\/__SITE_DATA__$/r site-data.js' "$userScript" \
        | sed '/^\/\/__SITE_DATA__$/d' > qute-goop-remover.user.js
      echo "selectors: $(wc -l < selectors.txt | tr -d ' ')  scoped: $(wc -l < scoped.txt | tr -d ' ')  unhide: $(wc -l < unhide.txt | tr -d ' ')"
      echo "bytes: css=$(wc -c < cosmetic.css | tr -d ' ') data=$(wc -c < site-data.js | tr -d ' ') js=$(wc -c < qute-goop-remover.user.js | tr -d ' ')"
    '';
    installPhase = ''
      mkdir -p $out/share/qutebrowser/greasemonkey
      cp cosmetic.css $out/share/qutebrowser/cosmetic.css
      cp qute-goop-remover.user.js $out/share/qutebrowser/greasemonkey/qute-goop-remover.user.js
    '';
  }
