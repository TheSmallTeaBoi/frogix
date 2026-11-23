{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.tmux;
  # Nerd Font Powerline half-circle caps, used to round the active-window
  # pill. Kept as JSON escapes so the source stays ASCII.
  pillLeft = builtins.fromJSON "\"\\uE0B6\"";
  pillRight = builtins.fromJSON "\"\\uE0B4\"";
in
{
  options.frogix."tmux".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "tmux with the pywal status theme";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      # Wheel scroll enters copy-mode instead of being forwarded to the
      # application as arrow keys.
      mouse = true;

      extraConfig =
        #tmux
        ''
          set -s escape-time 0

          # Let kitty graphics escape sequences through.
          # allow-passthrough is a window/pane option, so it must be set
          # globally; `set -s` has no current window during startup and
          # prints "no current window" on the first terminal after a reboot.
          set -g allow-passthrough on
          set -g prefix M-a
          set -g status-position bottom

          # Set titles correctly
          set -g set-titles on
          set -g set-titles-string "#T"

          # 0-Index makes sense for offsets, not this.
          set -g base-index 1
          setw -g pane-base-index 1

          # Me when this piece of software is still stuck in 1996
          set-option -g default-terminal "tmux-256color"
          set-option -g extended-keys on
          set-option -g extended-keys-format csi-u

          set -g status on
          set -g status-justify left
          set -g status-interval 0
          set -g status-left-length 40
          set -g status-right-length 40
          set -g status-left ""
          set -g status-right ""
          set -g window-status-separator ""
          # tmux underlines the current window by default; keep it flat.
          set -g window-status-current-style "nounderscore"

          # Palette push, re-run every time set-wal reloads this file (see
          # pywal.nix). `#[...]` are tmux format escapes; the shell only
          # substitutes the pywal variables. Each block resets to bg/fg so a
          # neighbouring segment never inherits the accent pill.
          #
          # run-shell expands formats in its argument, so the format codes
          # below are written as `##I`/`##W`: the outer expansion turns each
          # `##` into a literal `#`, leaving `#I`/`#W` for the inner `tmux set`
          # to store and render. Without this the window index/name expand to
          # nothing at config-load time.
          run-shell -b 'if [ -r ~/.cache/wal/colors.sh ]; then
            . ~/.cache/wal/colors.sh
            tmux \
              set -g status-style "bg=$background,fg=$foreground" \; \
              set -g status-left "" \; \
              set -g status-right "#[fg=$color8,bg=$background,nobold,nounderscore]  alt + space  for menu " \; \
              set -g window-status-format "#[fg=$color8,bg=$background,nounderscore] ##I  ##W " \; \
              set -g window-status-current-format "#[fg=$color1,bg=$background,nobold,nounderscore]${pillLeft}#[fg=$background,bg=$color1,bold,nounderscore] ##I  ##W #[fg=$color1,bg=$background,nobold,nounderscore]${pillRight}" \; \
              set -g window-status-activity-style "fg=$color2,bg=$background,nounderscore" \; \
              set -g window-status-bell-style "fg=$background,bg=$color2,bold,nounderscore" \; \
              set -g pane-border-style "fg=$color0" \; \
              set -g pane-active-border-style "fg=$color1" \; \
              set -g message-style "bg=$color0,fg=$foreground" \; \
              set -g mode-style "bg=$color1,fg=$background" \; \
              set -g clock-mode-colour "$color1" \; \
              set -g display-panes-colour "$color8" \; \
              set -g display-panes-active-colour "$color1"
          fi'

          # Reorder windows when one gets deleted.
          set -g renumber-windows on

          # Don't display status line if only 1 window
          if -F "#{==:#{session_windows},1}" "set -g status off" "set -g status on"
          set-hook -g window-linked 'if -F "#{==:#{session_windows},1}" "set -g status off" "set -g status on"'
          set-hook -g window-unlinked 'if -F "#{==:#{session_windows},1}" "set -g status off" "set -g status on"'

          # It's 2025, ffs
          set-option -g history-limit 250000

          # M-Space brings out the menu
          bind-key -n M-Space display-menu\
              "New Session"                        S "command-prompt -p \"New Session:\" \"new-session -A -s '%%'\"" \
              "Kill Session"                       x "kill-session" \
              "Kill Other Session(s)"              X "kill-session -a" \
              "" \
              "New Window"                          new-window \
              "With directory"                      "new-window -c '#{pane_current_path}'" \
              "Kill Window"                        󰆴 "killw"  \
              "Choose Window"                      󰒅 choose-window \
              "Previous Window"                     previous-window \
              "Next Window"                         next-window \
              "Swap Window Left"                    "swap-window -t -1" \
              "Swap Window Right"                   "swap-window -t +1" \
              "Horizontal Split"                    "split-window -h" \
              "Vertical Split"                      "split-window -v"  \
              "" \
              "Layout Horizontal"                   "select-layout even-horizontal"  \
              "Layout Vertical"                     "select-layout even-vertical"  \
              "" \
              "Swap Pane Up"                       < "swap-pane -U" \
              "Swap Pane Down"                     > "swap-pane -D" \
              "Break Pane"                         t break-pane \
              "Join Pane"                          j "choose-window 'join-pane -h -s \"%%\"'" \
              "#{?window_zoomed_flag,Unzoom,Zoom}" z "resize-pane -Z" \
              ""\
              "Lazygit"                             "new-window -n Lazygit -c '#{pane_current_path}' 'lazygit'" \
              "Bottom"                              "new-window -n Bottom 'btm'"



          bind                                     h split-window -h
          bind                                     v split-window -v
          bind -n                              M-Tab last-window
          bind -n                                M-n select-pane -t :.+
          bind -n                                M-p select-pane -t :.-

          # Go to window with Alt+1-9
          bind -n                                M-1 selectw -t 1
          bind -n                                M-2 selectw -t 2
          bind -n                                M-3 selectw -t 3
          bind -n                                M-4 selectw -t 4
          bind -n                                M-5 selectw -t 5
          bind -n                                M-6 selectw -t 6
          bind -n                                M-7 selectw -t 7
          bind -n                                M-8 selectw -t 8
          bind -n                                M-9 selectw -t 9


          # Unbind
          unbind                                '"'
          unbind                                %
        '';
    };
  };
}
