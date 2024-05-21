{
  inputs,
  outputs,
  pkgs,
  config,
  ...
}: {
  programs.tmux = {
    enable = true;
    plugins = with pkgs; [
      tmuxPlugins.catppuccin
    ];

    extraConfig = ''
      set -s escape-time 0
      set -g prefix M-a
      set -g status-position bottom

      # 0-Index makes sense for offsets, not this.
      set -g base-index 1
      setw -g pane-base-index 1

      # Activate mouse mode
      set -g mode-mouse on \;\
      set -g mouse-resize-pane on \;\
      set -g mouse-select-pane on \;\
      set -g mouse-select-window on \;\

      # Make catppuccin respect the window names.
      set -g @catppuccin_window_default_text "#W"
      set -g @catppuccin_window_current_text "#W"

      set -g @catppuccin_status_modules_right "application session"

      # Reorder windows when one gets deleted.
      set -g renumber-windows on

      # This is needed for catppuccin to work, for whatever reason...
      set-hook -g after-new-session "source-file ~/.config/tmux/tmux.conf"

      # It's 2024, ffs
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
          "Swap Window Right"                   "swap-window -t -1" \
          "Swap Window Left"                    "swap-window -t +1" \
          "Horizontal Split"                    "split-window -h" \
          "Vertical Split"                      "split-window -v"  \
          "" \
          "Layout Horizontal"                   "select-layout even-horizontal"  \
          "Layout Vertical"                     "select-layout even-horizontal"  \
          "" \
          "Swap Pane Up"                       < "swap-pane -U" \
          "Swap Pane Down"                     > "swap-pane -D" \
          "Break Pane"                         t break-pane \
          "Join Pane"                          j "choose-window 'join-pane -h -s \"%%\"'" \
          "#{?window_zoomed_flag,Unzoom,Zoom}" z "resize-pane -Z" \
          "" \
          "Nvim"                                "new-window -n "Nvim" -c '#{pane_current_path}' 'nvim'" \
          "With directory"                      "new-window -n "Nvim" -c '#{pane_current_path}' 'nvim .'" \
          "Notes"                              󰏪 "new-window -n "Notes" -c '/home/theo/Data/Personal/diary/' 'nvim notes.txt'" \
          "Nix"                                󱄅 "new-window -n "Nix" -c '/home/theo/frogix/' 'nvim .'" \
          ""\
          "Lazygit"                             "new-window -n "Lazygit" -c '#{pane_current_path}' 'lazygit'"
          "Bottom"                              "new-window -n "Bottom" 'btm'"



      bind                                     h split-window -h
      bind                                     v split-window -v
      bind -n                              M-Tab last-window

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
  home.file.".tmux.conf".text = config.xdg.configFile."tmux/tmux.conf".text; # This is the funniest piece of code in my config.
  # ^tmux.fish expects a config here. While home-manager writes it here ^
}
