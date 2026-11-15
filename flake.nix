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
      # url = "path:/home/theo/git/InFract/?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
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
    };
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      nix-index-database,
      sops-nix,
      hermes-agent,
      ...
    }@inputs:
    let
      # Every directory under hosts/ becomes a nixosConfigurations entry.
      # Add your own machine: hosts/<name>/default.nix importing ../../modules
      # plus your hardware-configuration.nix (hosts/ratholomew is the example),
      # then `git add` and rebuild with --flake .#<name>.
      mkHost =
        name:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            (./hosts + "/${name}")
            home-manager.nixosModules.home-manager
            inputs.musnix.nixosModules.musnix
            nix-index-database.nixosModules.nix-index
            sops-nix.nixosModules.sops
            inputs.niri-nix.nixosModules.default
            inputs.infract.nixosModules.default
          ];
        };
      hosts = nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts);
    in
    {
      nixosConfigurations = builtins.mapAttrs (name: _: mkHost name) hosts;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
