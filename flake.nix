{
  description = "Me when the linux";

  inputs = {
    # NixOS official package source, using the unstable branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    lsfg-vk-nix = {
      url = "github:Nyramu/lsfg-vk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    infract = {
      url = "github:NaokoAF/InFract/a53fc2f4184f125d44a225cdf8f0bff0b499d27c?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-index-database.follows = "nix-index-database";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-nix = {
      url = "git+https://codeberg.org/BANanaD3V/niri-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    doom-emacs = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # pi coding agent (earendil-works/pi), packaged by lukasl-dev. nixpkgs
    # follows ours per its README; the intel-darwin pin stays upstream's.
    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helper = {
      url = "github:TheSmallTeaBoi/helper";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # herdr — terminal workspace manager for coding agents (herdrdev/herdr);
    # pinned to the stable release, flake builds it from source
    herdr = {
      url = "github:herdrdev/herdr/v0.9.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      nix-index-database,
      sops-nix,
      ...
    }@inputs:
    let
      # every directory under hosts/ becomes a nixosConfigurations entry.
      # Add your own machine: hosts/<name>/default.nix importing ../../modules
      # plus your hardware-configuration.nix (hosts/ratholomew is the example),
      # then `git add` and rebuild with --flake .#<name>.
      #
      # the flake-input module wiring lives here (not in ./modules) so it stays
      # at flake scope — which also means the docs eval below can reuse it and
      # see the exact same option universe as a real host.
      hostModules = [
        home-manager.nixosModules.home-manager
        inputs.musnix.nixosModules.musnix
        nix-index-database.nixosModules.nix-index
        sops-nix.nixosModules.sops
        inputs.niri-nix.nixosModules.default
        inputs.infract.nixosModules.default
        inputs.helper.nixosModules.default
        inputs.impermanence.nixosModules.impermanence
      ];
      mkHost =
        name:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            (./hosts + "/${name}")
          ]
          ++ hostModules;
        };
      hosts = nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts);
    in
    {
      nixosConfigurations = builtins.mapAttrs (name: _: mkHost name) hosts;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;

      # docs/options.md, rendered from the live option trees so it cannot
      # drift from the code. regenerate with:
      #   nix eval --raw .#docs.optionsMd > docs/options.md
      docs.optionsMd =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          inherit (nixpkgs) lib;

          # bare evals: declarations only, config bodies stay lazy (frogix.enable
          # defaults off). options without universal defaults (hosts must set
          # them) get placeholders so defaults derived from them render — and
          # so home-manager's assertion pass (which homeManagerConfiguration
          # forces even when only options are read) can evaluate.
          nixosDocModule = {
            frogix.user = "user";
          };
          hmDocModule = {
            frogix.user = "user";
            frogix.home.stateVersion = "26.11";
            home.username = "user";
            home.homeDirectory = "/home/user";
            # home-manager's pkgsPath module argument reads this during its
            # config assertion pass, which homeManagerConfiguration forces
            home.stateVersion = "26.11";
          };

          nixosCommon =
            (pkgs.nixosOptionsDoc {
              options =
                (lib.nixosSystem {
                  system = "x86_64-linux";
                  modules = [
                    ./modules
                    nixosDocModule
                  ]
                  ++ hostModules;
                  specialArgs = { inherit inputs; };
                }).options.frogix;
            }).optionsCommonMark;

          hmCommon =
            (pkgs.nixosOptionsDoc {
              options =
                (home-manager.lib.homeManagerConfiguration {
                  pkgs = nixpkgs.legacyPackages.x86_64-linux;
                  modules = [
                    ./modules/home-manager
                    hmDocModule
                  ];
                  extraSpecialArgs = { inherit inputs; };
                }).options.frogix;
            }).optionsCommonMark;

          # cleanup: drop the declared-in blocks (file:/// store links, useless
          # in a rendered doc) and unescape the renderer's backslashes so
          # headings and prose read naturally: it writes `\$` for a literal
          # `$` and `\\` for a literal `\`, and a bare `\` before anything
          # else. unescape `\$` first, or the general rule would eat the `$`
          # and render `${VAR}` in a default as `.{VAR}`
          cleanOptionsMd =
            md:
            pkgs.runCommand "frogix-options-clean.md" { } ''
              awk '
                /^\*Declared by:\*$/ { skip = 1; next }
                skip == 1 && /^ - / { next }
                skip == 1 { skip = 0 }
                { print }
              ' ${md} | sed -e 's/\\\$/\$/g' -e 's/\\\([^$]\)/\1/g' > $out
            '';

          nixosMd = cleanOptionsMd nixosCommon;
          hmMd = cleanOptionsMd hmCommon;
          # a derivation so `nix eval` builds it, readFile so the regen one-liner
          # can dump the content directly:
          #   nix eval --raw .#docs.optionsMd > docs/options.md
          assembled = pkgs.runCommand "frogix-options.md" { } ''
            {
              cat ${./docs/options.header.md}
              printf '\n# system modules (nixos side)\n\n'
              cat ${nixosMd}
              printf '\n# home-manager modules (set under home-manager.users.<user>.frogix.*)\n\n'
              cat ${hmMd}
            } > $out
          '';
        in
        builtins.readFile assembled;
    };
}
