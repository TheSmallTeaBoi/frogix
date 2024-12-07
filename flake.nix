{
  description = "Me when the linux";

  inputs = {
    # NixOS official package source, using the unstable branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixvim = {
      url = "github:nix-community/nixvim/";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix = {url = "github:musnix/musnix";};

    nix-alien = {url = "github:thiagokokada/nix-alien";};

    yeetmouse = {
      url = "github:AndyFilter/YeetMouse?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
    nixvim,
    home-manager,
    yeetmouse,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    unfreePkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      ratholomew = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./configuration.nix
          ./modules
          home-manager.nixosModules.home-manager
          inputs.musnix.nixosModules.musnix
          yeetmouse.nixosModules.default
        ];
      };
    };
    packages = {
      ${system}.neovim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        pkgs = unfreePkgs;
        module = import ./modules/system/nixvim.nix;
      };
    };
  };
}
