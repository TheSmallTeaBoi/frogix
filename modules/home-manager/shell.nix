{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.shell;
in
{
  options.frogix."shell".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "fish + starship + tmux autostart shell stack";
  };

  config = lib.mkIf cfg.enable {
    # herdr's pane shell: herdr spawns $SHELL by default, and fish's frogix
    # interactive init execs every pane into tmux, nesting it inside herdr.
    # pin herdr panes to plain bash so they don't get dragged in.
    xdg.configFile."herdr/config.toml".source = ./herdr/config.toml;

    programs.fish = {
      enable = true;
      functions = {
        fish_greeting = "";

        # Kill tmux sessions nothing is attached to anymore
        tmux-clean = {
          description = "Kill tmux sessions with no attached clients";
          body = ''
            tmux list-sessions -F '#{session_name} #{session_attached}' \
              | awk '$2 == 0 {print $1}' \
              | xargs -r -n1 tmux kill-session -t
          '';
        };
      };
      plugins = [
      ];

      shellAliases = {
        det = "tmux detach";
        dev = "nix develop --command fish"; # This shit sucks
        e = "emacs";
        l = "eza -lh --icons --";
        la = "eza -a --icons --";
        ll = "eza -i --icons --";
        ls = "eza --icons --";
        nixb = "sudo nixos-rebuild switch --flake ~/frogix/";
        nsearch = "nix search nixpkgs";
        tree = "eza --tree --icons --";
      };
      # fix starship prompt to only have newlines after the first command
      # https://github.com/starship/starship/issues/560#issuecomment-1465630645
      shellInit =
        # Fish
        ''
          function postexec_newline --on-event fish_postexec
            echo ""
          end
        '';
      # add transient prompt for fish via transient.fish plugin in fish.nix
      # the starship transience module doesn't handle empty commands properly
      # https://github.com/starship/starship/issues/4929
      # exec tmux BEFORE starship/prompt init so terminals don't pay fish+starship
      # startup twice; grouped sessions set destroy-unattached so closing a
      # terminal cleans up its t-<pid> session without touching base.
      interactiveShellInit = lib.mkMerge [
        (lib.mkBefore (
          lib.optionalString config.frogix.tmux.enable
            # HERDR_ENV is set in herdr's panes: herdr IS the multiplexer there,
            # so exec'ing into tmux would nest it and hide agents behind tmux
            ''
              if not set -q TMUX
                  and not set -q HERDR_ENV
                  and not set -q INSIDE_EMACS
                  and not set -q VIM
                  and not set -q NVIM

              # Every terminal shares the same windows through grouped sessions,
              # but each gets its own current-window pointer.
              if tmux has-session -t base 2>/dev/null
                  exec tmux new-session -s "t-$fish_pid" -t base \; set-option destroy-unattached on
              else
                  exec tmux new-session -A -s base
              end
              end
            ''
        ))
        (lib.mkAfter ''
          function transient_prompt_func
            starship module character
          end
        '')
      ];
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
      settings =
        let
          bg = "1";
          fg = "0";

          accent_style = "bg:${bg} fg:${fg}";
          important_style = "bg:${fg} fg:${bg}";
        in
        {
          add_newline = false;
          format = lib.concatStrings [
            # begin left format
            "$username"
            "$hostname"
            "$directory[](${bg}) "
            # end left format
            "$fill"
            # begin right format
            "[█](${bg})"
            "[](${accent_style})"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$nix_shell"
            "[█](${bg})"
            # end right format
            "$line_break"
            "$character"
          ];

          # modules
          character = {
            error_symbol = "[ ](${bg})";
            success_symbol = "[](${bg})";
            vimcmd_symbol = "[](${bg})";
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
  };
}
