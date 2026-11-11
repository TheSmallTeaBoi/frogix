#!/bin/sh
# update-qute-lists.sh - bump the pinned easylist + uBO uAssets revs in bundle.nix.
# usage: ./update-qute-lists.sh [easylist-rev [uassets-rev]]  (default: master HEADs)
# needs: curl, nix. fetchFromGitHub hashes the *unpacked* tree, so we use
# nix-prefetch-url --unpack (NOT nix store prefetch-file, which hashes the file).
set -eu
cd "$(dirname "$0")"
NIXFILE="bundle.nix"

pin() {
  REPO="$1"
  REV="$2"
  echo "$REPO -> $REV"
  NIX32=$(nix-prefetch-url --unpack \
    "https://github.com/$REPO/archive/$REV.tar.gz" 2>/dev/null | tail -n 1)
  HASH=$(nix hash convert --hash-algo sha256 --to sri "$NIX32" 2>/dev/null)

  awk -v repo="$REPO" -v rev="$REV" -v hash="$HASH" '
    $0 ~ "repo = \"" repo "\"" { inrepo = 1 }
    inrepo && /rev = "/ { sub(/"[0-9a-f]{40}"/, "\"" rev "\""); }
    inrepo && /hash = "sha256-/ { sub(/sha256-[A-Za-z0-9+\/=]+/, hash); inrepo = 0 }
    { print }
  ' "$NIXFILE" > "$NIXFILE.new"
  mv "$NIXFILE.new" "$NIXFILE"
}

EL_REPO="easylist/easylist"
UA_REPO="uBlockOrigin/uAssets"

if [ "$#" -ge 1 ]; then
  EL_REV="$1"
else
  EL_REV=$(curl -s --max-time 30 "https://api.github.com/repos/$EL_REPO/commits/master" \
    | grep '"sha"' | head -n 1 | cut -d'"' -f4)
fi
if [ "$#" -ge 2 ]; then
  UA_REV="$2"
else
  UA_REV=$(curl -s --max-time 30 "https://api.github.com/repos/$UA_REPO/commits/master" \
    | grep '"sha"' | head -n 1 | cut -d'"' -f4)
fi

pin "$EL_REPO" "$EL_REV"
pin "$UA_REPO" "$UA_REV"
grep -n 'rev = \|hash = ' "$NIXFILE" | head -n 4
echo "now: rebuild, verify qute, commit the diff."
