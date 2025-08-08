{...}: {
  programs.bottom = {
    enable = true;
    settings = {
      flags = {
        enable_gpu = true;
        rate = "500ms";
      };
    };
  };
}
