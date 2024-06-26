{...}: {
  programs.lazygit = {
    enable = true;
    settings = {
      gui.theme = {
        # Use the catppuccin latte theme
        activeBorderColor = [
          "#89b4fa"
          "bold"
        ];
        inactiveBorderColor = ["#6c6f85"];
        optionsTextColor = ["#1e66f5"];
        selectedLineBgColor = ["#313244"];
        selectedRangeBgColor = ["#313244"];
        cherryPickedCommitBgColor = ["#bcc0cc"];
        cherryPickedCommitFgColor = ["#1e66f5"];
        unstagedChangesColor = ["#d20f39"];
        defaultFgColor = ["#4c4f69"];
        searchingActiveBorderColor = ["#df8e1d"];
      };
    };
  };
}
