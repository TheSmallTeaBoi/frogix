{
  pkgs,
  lib,
  ...
}: {
  home.sessionVariables = {
    fish_tmux_config = "~/.config/tmux/tmux.config";
  };
  programs.fish = {
    enable = true;
    functions = {
      fish_greeting = "";
      # fish_prompt = "set_color red; echo $IN_NIX_SHELL '> '";
    };
    plugins = [
    ];

    shellAliases = {
      ls = "eza --icons";
      la = "eza -a --icons";
      ll = "eza -i --icons";
      tree = "eza --tree --icons";
      nixb = "sudo nixos-rebuild switch --flake ~/frogix/";
      nsearch = "nix search nixpkgs";
      dev = "nix develop --command fish"; # This shit sucks
      det = "tmux detach";
    };
    # fix starship prompt to only have newlines after the first command
    # https://github.com/starship/starship/issues/560#issuecomment-1465630645
    shellInit = ''
      function postexec_newline --on-event fish_postexec
        echo ""
      end
    '';
    # add transient prompt for fish via transient.fish plugin in fish.nix
    # the starship transience module doesn't handle empty commands properly
    # https://github.com/starship/starship/issues/4929
    interactiveShellInit =
      lib.mkAfter
      # fish
      ''
        function transient_prompt_func
          starship module character
        end

        # Enter tmux if not started
        if not set -q TMUX
          set -g TMUX tmux new-session -d -s base
          eval $TMUX
          tmux attach-session -t base
        end
      '';
  };

  # fish plugins, home-manager's programs.fish.plugins has a weird format
  home.packages = with pkgs.fishPlugins; [
    # used as starship's transient prompt does not handle empty commands
    transient-fish
  ];

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = let
      dir_bg = "#ea76cb";
      accent_style = "bg:${dir_bg} fg:#4c4f69";
      important_style = "bg:#4c4f69 fg:#eff1f5";
    in {
      add_newline = false;
      format = lib.concatStrings [
        # begin left format
        "$username"
        "$hostname"
        "$directory[](${dir_bg}) "
        # end left format
        "$fill"
        # begin right format
        "[█](${dir_bg})"
        "[](${accent_style})"
        "$git_branch"
        "$git_state"
        "$git_status"
        "$nix_shell"
        "[█](${dir_bg})"
        # end right format
        "$line_break"
        "$character"
      ];

      # modules
      character = {
        error_symbol = "[ ](bold red)";
        success_symbol = "[](purple)";
        vimcmd_symbol = "[](green)";
      };
      username = {
        style_root = important_style;
        style_user = important_style;
        format = "[ $user in ]($style)";
      };
      hostname = {
        style = important_style;
      };
      directory = {
        format = "[ $path ]($style)";
        style = accent_style;
      };
      git_branch = {
        symbol = "";
        format = "[ $symbol $branch]($style)";
        style = accent_style;
      };
      git_state = {
        format = "([ $state( $progress_current/$progress_total)]($style)) ";
        style = accent_style;
      };
      git_status = {
        conflicted = "​";
        deleted = "​";
        format = "[[ (*$conflicted$untracked$modified$staged$renamed$deleted)]($style)($ahead_behind$stashed)]($style)";
        modified = "​";
        renamed = "​";
        staged = "​";
        stashed = "≡";
        style = accent_style;
        untracked = "​";
      };
      nix_shell = {
        format = "[ $symbol]($style)";
        symbol = "";
        style = accent_style;
      };
      fill = {
        symbol = "";
      };
      line_break = {
        disabled = false;
      };
      time = {
        format = "[ $time]($style)";
        disabled = false;
        time_format = "%H:%M";
        style = accent_style;
      };
    };
  };
}
