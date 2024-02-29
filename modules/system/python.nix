{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    conda
    (python311.withPackages (ps:
      with ps; [
        virtualenv
        pypresence
        pydbus
      ]
    ))
  ];
}
