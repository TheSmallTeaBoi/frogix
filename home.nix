{
  inputs,
  pkgs,
  config,
  outputs,
  ...
}: {
  imports = [inputs.home-manager.nixosModules.home-manager];
  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    useGlobalPkgs = false;
    useUserPackages = true;
    users = {
      # Import your home-manager configuration
      theo = import ./home-manager;
    };
  };
}
