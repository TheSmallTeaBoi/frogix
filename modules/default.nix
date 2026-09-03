{
  inputs,
  outputs,
  ...
}:
{
  imports = [
    ./system
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      # Import your home-manager configuration
      theo = import ./home-manager;
    };
  };
}
