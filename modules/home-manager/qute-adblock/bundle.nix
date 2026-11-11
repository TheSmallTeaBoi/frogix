{ pkgs, lib }:
# qute-adblock bundle — compiles git-pinned easylist + uBO uAssets components
# into the engine userscript (rule data spliced at //__DATA__ by ./compile.py).
# test directly:
#   nix-build -E 'with import <nixpkgs> {}; import ./bundle.nix { inherit pkgs lib; }'
let
  easylist = pkgs.fetchFromGitHub {
    owner = "easylist";
    repo = "easylist";
    rev = "e2ad8fb40f271e2d70917f755f1aad2a54d5e2b5";
    hash = "sha256-2uxK3I07Y9Q8gXIH19Nbpi9HYetZeXWRYNQ01DaYoAQ=";
  };
  uassets = pkgs.fetchFromGitHub {
    owner = "uBlockOrigin";
    repo = "uAssets";
    rev = "59a0f859080dcb1cf12417dd3fb6559fd5525c5b";
    hash = "sha256-T3e17Y9+Nkx45C0scIFDZY6T6aaXbau2mo7fG4b4rTI=";
  };
  xfiles = pkgs.fetchFromGitHub {
    owner = "gioxx";
    repo = "xfiles";
    rev = "78cae2d427010ca359d15765f819363cebe1d000";
    hash = "sha256-SYmegVmoNGFZpT7gZixWB3viZ3GryJlH/oLtduAFUpE=";
  };
  adfilt = pkgs.fetchFromGitHub {
    owner = "DandelionSprout";
    repo = "adfilt";
    rev = "57c959cb067f04f1bfa51ae391728c52daafea63";
    hash = "sha256-THOAkSKbrhqHJxoPz6koR8rUVWo4bkylF3i71cLjwWI=";
  };
in
pkgs.stdenvNoCC.mkDerivation {
  name = "qute-adblock-bundle";
  nativeBuildInputs = [ pkgs.python3 ];
  dontUnpack = true;
  installPhase = ''
    python3 ${./compile.py} \
      --easylist ${easylist} \
      --uassets ${uassets} \
      --xfiles ${xfiles} \
      --adfilt ${adfilt} \
      --engine ${./engine.user.js} \
      --out $out/share/qutebrowser
  '';
}
