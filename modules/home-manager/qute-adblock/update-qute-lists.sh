#!/bin/sh
# update-qute-lists.sh - bump the pinned easylist/easylist rev in default.nix.
# usage: ./update-qute-lists.sh [rev]   (default: current master HEAD)
# needs: curl, nix. fetchFromGitHub hashes the *unpacked* tree, so we use
# nix-prefetch-url --unpack (NOT nix store prefetch-file, which hashes the file).
set -eu
cd "$(dirname "$0")"
NIXFILE="bundle.nix"

if [ "$#" -ge 1 ]; then
  REV="$1"
else
  REV=$(curl -s --max-time 30 "https://api.github.com/repos/easylist/easylist/commits/master" \
    | grep '"sha"' | head -n 1 | cut -d'"' -f4)
fi
echo "rev: $REV"
NIX32=$(nix-prefetch-url --unpack \
  "https://github.com/easylist/easylist/archive/$REV.tar.gz" 2>/dev/null | tail -n 1)
HASH=$(nix hash convert --hash-algo sha256 --to sri "$NIX32" 2>/dev/null)
echo "hash: $HASH"

sed -i "s|rev = \"[0-9a-f]\\{40\\}\";|rev = \"$REV\";|" "$NIXFILE"
awk -v hash="$HASH" '
  /rev = "[0-9a-f]{40}";/ {want=1}
  want==1 && /hash = "sha256-/ {sub(/sha256-[A-Za-z0-9+\/=]+/, hash); want=0}
  {print}
' "$NIXFILE" > "$NIXFILE.new"
mv "$NIXFILE.new" "$NIXFILE"
grep -n 'rev = \|hash = ' "$NIXFILE" | head -n 4
echo "now: rebuild, verify qute, commit the diff."
