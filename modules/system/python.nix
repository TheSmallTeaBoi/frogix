{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    conda
    (python312.withPackages (ps:
      with ps; [
        virtualenv
        pypresence
        pydbus
        tkinter
      ]
    ))
  ];
}
