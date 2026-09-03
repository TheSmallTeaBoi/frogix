{
  config,
  lib,
  pkgs,
  ...
}:
let
  walCache = "${config.home.homeDirectory}/.cache/wal";

  set-wal = (
    let
      pywal16-full = pkgs.pywal16.override {
        withColorthief = true;
        withColorz = true;
        withFastColorthief = true;
        withHaishoku = true;
        withModernColorthief = true;
      };
    in
    pkgs.writeShellApplication {
      name = "set-wal";
      runtimeInputs = with pkgs; [
        pywal16-full
        awww
        qutebrowser
        procps
        mako
        pywalfox-native
      ];
      text = ''
        set -euo pipefail
        set -x

        if [ "$#" -lt 1 ]; then
          echo "usage: wal-set <image-or-pywal-args...>" >&2
          exit 2
        fi

        wal --backend colorz -n -i "$@" || true
        awww img "$1" --transition-type any --transition-duration 2 --transition-fps 180
        qutebrowser --target auto ":config-source"
        pkill -USR2 waybar 2>/dev/null || true
        makoctl reload 2>/dev/null || true
        pkill -USR1 kitty 2>/dev/null || true
        if command -v tmux >/dev/null 2>&1; then
          tmux source-file ~/.config/tmux/tmux.conf >/dev/null 2>&1 || true
        fi

        pywalfox update

        ln -sf ~/.cache/wal/vesktop.css ~/.config/vesktop/themes/custom.css

        if command -v emacsclient >/dev/null 2>&1; then
          emacsclient --eval '(load-file "~/.config/emacs/pywal.el")' >/dev/null 2>&1 || true
        fi
      '';
    }
  );
in
{

  home.packages = [
    set-wal
  ];

  systemd.user.services.wal-cycle = {
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "wal-cycle" ''
        ${set-wal}/bin/set-wal "$(find /storage/Walls -type f | shuf -n 1)"
      ''}";
    };
  };

  systemd.user.timers.wal-cycle = {
    Timer = {
      OnBootSec = "15min";
      OnUnitActiveSec = "15min";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  xdg.configFile = {
    "wal/templates/mako-colors".text = ''
      background-color={background}
      text-color={foreground}
      border-color={color4}
      border-radius=5
      margin=20

      border-size=3
    '';

    "wal/templates/niri-colors.kdl".text = ''
      layout {
        background-color "{background}"
        gaps 9
        focus-ring {
            active-color "{color1}"
            inactive-color "#00000000"
            urgent-color "{color7}"
            width 3
        }
        border {
            width 0
        }
        shadow {
            color "{background}80"
        }
      }
    '';

    "wal/templates/colors-kitty.conf".text = ''
      foreground         {foreground}
      background         {background}
      cursor             {cursor}

      active_tab_foreground     {background}
      active_tab_background     {foreground}
      inactive_tab_foreground   {foreground}
      inactive_tab_background   {background}

      active_border_color   {foreground}
      inactive_border_color {background}
      bell_border_color     {color1}

      color0       {color0}
      color8       {color8}
      color1       {color1}
      color9       {color9}
      color2       {color2}
      color10      {color10}
      color3       {color3}
      color11      {color11}
      color4       {color4}
      color12      {color12}
      color5       {color5}
      color13      {color13}
      color6       {color6}
      color14      {color14}
      color7       {color7}
      color15      {color15}
    '';

    "wal/templates/waybar.css".text =
      #css
      ''
        @define-color background {background};
        @define-color foreground {foreground};
        @define-color color0 {color0};
        @define-color color1 {color7};
        @define-color color2 {color2};
        @define-color color4 {color1};
      '';

    "wal/templates/vesktop.css".text =
      #css
      ''
        /* import theme modules */
        @import url('https://refact0r.github.io/midnight-discord/build/midnight.css');

        /* color options */
        :root {
            --colors: on;

            /* text colors */
            --text-0: {background};   /* text on colored elements */
            --text-1: {foreground};   /* bright white-ish text */
            --text-2: {foreground};   /* headings */
            --text-3: {foreground};   /* normal text */
            --text-4: {foreground};   /* icons/channels */
            --text-5: {foreground};   /* muted  */

            /* background and dark colors */
            --bg-1: color-mix(in srgb, {color8} 50%, {background}00);
            --bg-2: color-mix(in srgb, {color8} 50%, {background}00);
            --bg-3: color-mix(in srgb, {color8} 50%, {background}00);
            --bg-4: {background}b3;
            --hover: {color8}1a; /* channels and buttons when hovered */
            --active: {color8}33; /* channels and buttons when clicked or selected */
            --active-2: {color8}4d; /* extra state for transparent buttons */
            --message-hover: #0000001a; /* messages when hovered */

            /* accent colors */
            --accent-1: {color7}; /* links and other accent text */
            --accent-2: {color12}; /* small accent elements */
            --accent-3: {color4}; /* accent buttons */
            --accent-4: {color12}; /* accent buttons when hovered */
            --accent-5: {color4}; /* accent buttons when clicked */
            --accent-new: var(--accent-2);
            --mention: linear-gradient(to right, color-mix(in hsl, {color12}, transparent 90%) 40%, transparent);
            --mention-hover: linear-gradient(to right, color-mix(in hsl, {color12}, transparent 95%) 40%, transparent);
            --reply: linear-gradient(to right, color-mix(in hsl, {color15}, transparent 90%) 40%, transparent);
            --reply-hover: linear-gradient(to right, color-mix(in hsl, {color15}, transparent 95%) 40%, transparent);

            /* status indicator colors */
            --online: {color6};
            --dnd: {color1};
            --idle: {color5};
            --streaming: {color3};
            --offline: {color7};

            /* border colors */
            --border-light: var(--hover);
            --border: var(--active);
            --border-hover: var(--active);
            --button-border: {color8}1a;

            /* base colors */
            --red-1: {color9};
            --red-2: {color1};
            --red-3: {color1};
            --red-4: {color1};
            --red-5: {color1};

            --green-1: {color10};
            --green-2: {color2};
            --green-3: {color2};
            --green-4: {color2};
            --green-5: {color2};

            --blue-1: {color12};
            --blue-2: {color4};
            --blue-3: {color4};
            --blue-4: {color4};
            --blue-5: {color4};

            --yellow-1: {color11};
            --yellow-2: {color3};
            --yellow-3: {color3};
            --yellow-4: {color3};
            --yellow-5: {color3};

            --purple-1: {color13};
            --purple-2: {color5};
            --purple-3: {color5};
            --purple-4: {color5};
            --purple-5: {color5};
        }
      '';
    "wal/templates/emacs.el".text =
      #elisp
      ''
        (setq doom-font (font-spec :family "Maple Mono NF" :size 14))
        (setq doom-variable-pitch-font (font-spec :family "Noto Sans" :size 14))
        (setq nerd-icons-font-family "Maple Mono NF")
        (setq doom-symbol-font (font-spec :family "Maple Mono NF"))

        (set-face-attribute 'font-lock-comment-face nil :slant 'italic)
        (set-face-attribute 'font-lock-function-name-face nil :slant 'italic)
        (set-face-attribute 'font-lock-variable-name-face nil :slant 'italic)

        (defun frogix/apply-pywal-theme ()
          (custom-set-faces!
            `(default                              :background "{background}" :foreground "{foreground}")
            `(region                               :background "{color8}")
            `(hl-line                              :background "{color0}")
            `(solaire-default-face                 :background "{background}")
            `(solaire-hl-line-face                 :background "{color0}")
            `(solaire-mode-line-face               :background "{color0}")
            `(solaire-mode-line-inactive-face      :background "{background}")
            `(mode-line                            :background "{color0}"   :foreground "{foreground}")
            `(mode-line-inactive                   :background "{background}" :foreground "{color8}")
            '(doom-modeline-buffer-file            :background unspecified)
            '(doom-modeline-buffer-path            :background unspecified)
            '(doom-modeline-buffer-modified        :background unspecified)
            '(doom-modeline-project-dir            :background unspecified)
            '(doom-modeline-info                   :background unspecified)
            '(doom-modeline-warning                :background unspecified)
            `(minibuffer-prompt                    :foreground "{color4}")
            `(font-lock-keyword-face               :foreground "{color5}")
            `(font-lock-type-face                  :foreground "{color3}")
            `(font-lock-constant-face              :foreground "{color9}")
            `(font-lock-string-face                :foreground "{color2}")
            `(font-lock-comment-face               :foreground "{color8}")
            `(font-lock-variable-name-face         :foreground "{color1}")
            `(font-lock-function-name-face         :foreground "{color4}")))

        (add-hook 'after-make-frame-functions
                  (lambda (frame)
                    (with-selected-frame frame
                      (doom/reload-font)
                      (frogix/apply-pywal-theme))))
        (add-hook 'doom-load-theme-hook #'frogix/apply-pywal-theme)

        (when doom-theme
          (run-hooks 'doom-load-theme-hook))

      '';

    "emacs/pywal.el".source = config.lib.file.mkOutOfStoreSymlink "${walCache}/emacs.el";
    "vesktop/themes/custom.css".source = config.lib.file.mkOutOfStoreSymlink "${walCache}/vesktop.css";
  };

  home.activation.seedPywal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${walCache}"
    if [ ! -e "${walCache}/colors.sh" ]; then
      verboseEcho "Seeding pywal cache with base16-da-one-sea"
      ${pkgs.pywal16}/bin/wal --theme base16-da-one-sea -n -q
    else
      verboseEcho "Refreshing pywal templates from the existing cache"
      ${pkgs.pywal16}/bin/wal -R -n -q || true
    fi
  '';

}
