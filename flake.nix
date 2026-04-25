{
  description = "Me when the linux";

  inputs = {
    # NixOS official package source, using the unstable branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nixvim = {
    #   url = "github:nix-community/nixvim/";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    musnix = {
      url = "github:musnix/musnix";
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
    };

    yeetmouse = {
      url = "github:AndyFilter/YeetMouse?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plover-flake.url = "github:openstenoproject/plover-flake";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
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
  };
  outputs =
    {
      nixpkgs,
      nixvim,
      home-manager,
      yeetmouse,
      nix-index-database,
      stylix,
      sops-nix,
      ...
    }@inputs:
    let
      ratholomewConfig = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./modules
          home-manager.nixosModules.home-manager
          inputs.musnix.nixosModules.musnix
          yeetmouse.nixosModules.default
          nix-index-database.nixosModules.nix-index
          stylix.nixosModules.stylix
          sops-nix.nixosModules.sops
        ];
      };
    in
    {
      nixosConfigurations.ratholomew = ratholomewConfig;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
