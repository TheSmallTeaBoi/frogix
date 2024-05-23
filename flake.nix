{
  description = "Me when the linux";

  inputs = {
    # NixOS official package source, using the unstable branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixvim = {
      url = "github:nix-community/nixvim/";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    nixvim,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    neovim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
      module = import ./modules/system/nixvim;
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
        ];
      };
    };
    packages = {
      ${system}.neovim = neovim;
    };
  };
}
