{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.pywal;
  walCache = "${config.home.homeDirectory}/.cache/wal";

  quteRestart = lib.optionalString config.frogix.qutebrowser.enable ''
    cdp_port="''${RICE_CDP_PORT:-9222}"
    if [ "$restart_qute" = 1 ] && pgrep -f 'bin/[.]qutebrowser-wrapped' >/dev/null 2>&1; then
      if ! curl -sf --max-time 1 "http://127.0.0.1:$cdp_port/json/version" >/dev/null 2>&1; then
        qutebrowser --target auto ":restart" || true
      fi
    fi
  '';

  pywal16-full = pkgs.pywal16.override {
    withColorthief = true;
    withColorz = true;
    withFastColorthief = true;
    withHaishoku = true;
    withModernColorthief = true;
  };

  # niri exits on a missing `include` — this lands in ${walCache}/niri-colors.kdl
  # whenever wal could not render (headless/foreign-terminal activation) so the
  # first niri session always starts. the first successful set-wal overwrites it.
  niriColorsFallback = pkgs.writeText "niri-colors-fallback.kdl" ''
    layout {
        background-color "#10121a"
        gaps 9
        focus-ring {
            active-color "#39424e"
            inactive-color "#00000000"
            urgent-color "#c75d5d"
            width 3
        }
        border {
            width 0
        }
        shadow {
            color "#00000050"
        }
    }
  '';

  # One file decides the rice's mode. Every consumer reads it:
  #   set-wal        -> pywal palette (light = `wal -l` + a contrast fix)
  #   qutebrowser    -> config.py sets colors.webpage.preferred_color_scheme
  #   vitrina/kitty  -> through the pywal cache (colors.json / colors-kitty.conf)
  #   GTK/libadwaita -> through dconf (color-scheme + theme variant)
  riceModeFile = "${config.home.homeDirectory}/.config/rice/mode";

  # pywal's -l palette gets the background/foreground right but keeps the
  # wallpaper's original accent hues, which were picked to sit on a dark
  # background. On a near-white bg the pale ones drop to ~1.3:1 (measured on
  # random /storage/Walls picks) — invisible focus rings, tab indicators and
  # terminal ANSI colors. Two repairs, then `wal -R` re-exports every template:
  #   color8        -> muted/secondary TEXT slot, floor 4.5:1
  #   color1-6,9-14 -> accent slots, floor 3.5:1 (blend toward black: keeps hue)
  # Foreground lands at ~9.9:1 on its own; nothing else is touched.
  modeFix = pkgs.writeText "wal-light-contrast.py" ''
    import json
    import sys

    path = sys.argv[1]
    with open(path) as f:
        data = json.load(f)

    bg = data["special"]["background"]
    fg = data["special"]["foreground"]
    slot = data["colors"]["color8"]


    def rgb(h):
        h = h.lstrip("#")
        return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


    def lum(h):
        def chan(c):
            return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

        r, g, b = rgb(h)
        return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)


    def contrast(a, b):
        la, lb = lum(a), lum(b)
        hi, lo = max(la, lb), min(la, lb)
        return (hi + 0.05) / (lo + 0.05)


    def blend(a, b, t):
        ca, cb = rgb(a), rgb(b)
        return "#%02x%02x%02x" % tuple(
            round((ca[i] + (cb[i] - ca[i]) * t) * 255) for i in range(3))


    def raise_to(col, target, towards):
        fixed = col
        t = 0.0
        while contrast(bg, fixed) < target and t < 1.0:
            t += 0.05
            fixed = blend(col, towards, t)
        return fixed

    data["colors"]["color8"] = raise_to(slot, 4.5, fg)

    accents = ["color%d" % i for i in range(1, 7)] + \
              ["color%d" % i for i in range(9, 15)]
    for name in accents:
        data["colors"][name] = raise_to(data["colors"][name], 3.5, "#000000")

    with open(path, "w") as f:
        json.dump(data, f, indent=4)
  '';

  set-wal = (
    pkgs.writeShellApplication {
      name = "set-wal";
      runtimeInputs =
        with pkgs;
        [
          pywal16-full
          awww
          procps
          pywalfox-native
          glib # gsettings/glib runtime (kept for the pywalfox path)
          dconf # gtk-theme / icon-theme / color-scheme, schema-free
          python3
          coreutils
          gnused
        ]
        ++ lib.optionals config.frogix.niri.enable [ niri ]
        ++ lib.optionals config.frogix.qutebrowser.enable [ qutebrowser ];
      text = ''
        set -euo pipefail
        set -x

        if [ "$#" -lt 1 ]; then
          echo "usage: wal-set <image-or-pywal-args...>" >&2
          exit 2
        fi

        mode_file="${riceModeFile}"
        mode="dark"
        if [ -r "$mode_file" ]; then
          mode="$(tr -d '[:space:]' < "$mode_file")"
        fi
        if [ "$mode" != "light" ]; then
          mode="dark"
        fi

        # dark palettes come from the k-means backend (frogix.pywal.darkBackend);
        # wal's background darkening muddies bright wallpapers. light mode always
        # uses wal — its derived background behaves there and modeFix expects it.
        if [ "$mode" = "light" ]; then
          wal_args=(--backend wal -l -n)
        else
          wal_args=(--backend ${cfg.darkBackend} -n)
        fi
        wal "''${wal_args[@]}" -i "$@" || true

        if [ "$mode" = "light" ]; then
          python3 ${modeFix} "$HOME/.cache/wal/colors.json" || true
          # -R re-exports every template (kitty, niri, gtk, qt, emacs, ...) from
          # the contrast-patched palette; -n leaves the wallpaper alone.
          wal -R -n -q || true
        fi

        # The one dconf key that must follow the mode: the portal color-scheme
        # that libadwaita / chromium / electron / firefox read. dconf directly —
        # gsettings without a schema dir silently did nothing here.
        # gtk-theme and icon-theme stay declared in gtk.nix (home-manager's gtk
        # module re-derives them from gtk.theme.name on every activation, so
        # writing them here would just be a losing fight, and GTK3 reads the
        # name from settings.ini anyway).
        if [ "$mode" = "light" ]; then
          color_scheme="prefer-light"
        else
          color_scheme="prefer-dark"
        fi
        dconf write /org/gnome/desktop/interface/color-scheme "'$color_scheme'" 2>/dev/null || true

        awww img "$1" --transition-type any --transition-duration 2 --transition-fps 180

        ${lib.optionalString config.frogix.qutebrowser.enable ''
          # only poke an instance that is already running: a CLI call with no
          # IPC peer opens a whole browser window.
          if pgrep -f 'bin/[.]qutebrowser-wrapped' >/dev/null 2>&1; then
            qutebrowser --target auto ":config-source" || true
          fi
        ''}

        ${lib.optionalString config.frogix.niri.enable ''
          # niri only auto-reloads on config.kdl edits, not on this include.
          niri_sock="''${NIRI_SOCKET:-}"
          if [ -z "$niri_sock" ]; then
            niri_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
            for s in "$niri_dir"/niri.wayland-1.*.sock; do
              if [ -S "$s" ]; then
                niri_sock="$s"
                break
              fi
            done
          fi
          if [ -n "$niri_sock" ]; then
            NIRI_SOCKET="$niri_sock" niri msg action reload-config >/dev/null 2>&1 || true
          fi
        ''}

        # pywalfox only has a target when firefox exists; never abort set-wal
        # over it (set -e is on).
        pywalfox update || true

        ${lib.optionalString config.frogix.vesktop.enable ''
          ln -sf ~/.cache/wal/vesktop.css ~/.config/vesktop/themes/custom.css
        ''}

        if command -v emacsclient >/dev/null 2>&1; then
          emacsclient --eval '(load-file "~/.config/emacs/pywal.el")' >/dev/null 2>&1 || true
        fi

        ${lib.optionalString config.frogix.tmux.enable ''
          # reload tmux's config so its run-shell re-sources the colors.sh wal
          # just regenerated; the status line, borders and modes then follow the
          # new wallpaper without restarting the server. re-sourcing the config
          # keeps the palette definition in one place (tmux.nix) instead of
          # duplicating it here. no server running is a silent no-op.
          if command -v tmux >/dev/null 2>&1; then
            tmux source-file ${config.xdg.configHome}/tmux/tmux.conf >/dev/null 2>&1 || true
          fi
        ''}
      '';
    }
  );

  # rice-mode [light|dark|toggle] — no argument prints the current mode.
  # Flips the marker, re-derives the palette from the wallpaper that is on
  # screen, and restarts qutebrowser (its website color scheme is a startup-only
  # blink setting: configdata.yml marks it `restart: true`, and `:restart`
  # reloads the saved session so tabs come back).
  rice-mode = pkgs.writeShellApplication {
    name = "rice-mode";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        gnused
        gnugrep
        procps
        curl
        set-wal
      ]
      ++ lib.optionals config.frogix.qutebrowser.enable [ qutebrowser ];
    text = ''
      set -euo pipefail

      mode_file="${riceModeFile}"
      current="dark"
      if [ -r "$mode_file" ]; then
        current="$(tr -d '[:space:]' < "$mode_file")"
      fi

      restart_qute=1
      args=()
      for arg in "$@"; do
        case "$arg" in
          --no-qute) restart_qute=0 ;;
          *) args+=("$arg") ;;
        esac
      done

      want="''${args[0]:-}"
      case "$want" in
        "") echo "$current"; exit 0 ;;
        light|dark) ;;
        toggle)
          if [ "$current" = "light" ]; then
            want="dark"
          else
            want="light"
          fi
          ;;
        *)
          echo "usage: rice-mode [light|dark|toggle] [--no-qute]" >&2
          exit 2
          ;;
      esac

      mkdir -p "$(dirname "$mode_file")"
      printf '%s\n' "$want" > "$mode_file"

      wall="$(sed -n 's/.*"wallpaper": *"\(.*\)",*$/\1/p' "$HOME/.cache/wal/colors.json" 2>/dev/null | head -n1)"
      if [ -z "$wall" ] || [ ! -e "$wall" ]; then
        wall="$(find ${config.frogix.wallpapersDir} -type f | shuf -n 1)"
      fi
      set-wal "$wall"

      # live path: config.py re-applies the mode to every open page over the
      # devtools protocol (ricecdp.py), triggered by the :config-source set-wal
      # already sent. Restart only when that port is missing, i.e. qute was
      # started without QTWEBENGINE_REMOTE_DEBUGGING (blink flag is the only
      # lever then, and that one is startup-only).
      ${quteRestart}

      echo "rice mode: $want"
    '';
  };
in
{
  options.frogix.pywal.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "pywal16 rice engine: set-wal, light mode and every consumer template";
  };

  options.frogix.pywal.darkBackend = lib.mkOption {
    type = lib.types.str;
    default = "colorz";
    description = ''
      Backend pywal uses to extract dark-mode palettes. Light mode always uses wal.

      wal derives the background by darkening the darkest quantized colour, which
      on bright or pastel wallpapers lands on murky desaturated tones (measured
      `#1f2921` on the bundled wallpaper, 2026-11-17). The k-means backends keep the
      background anchored near-black with bolder accents, so dark mode defaults to
      colorz. Must name a backend pywal16-full ships: wal, colorthief,
      fast_colorthief, modern_colorthief, haishoku or colorz.
    '';
  };

  options.frogix.pywal.cycleInterval = lib.mkOption {
    type = lib.types.int;
    default = 15;
    description = "minutes between wallpaper shuffles (0 = pick one at login and stay on it)";
  };

  config = lib.mkIf cfg.enable {

    # the knob must name a backend this module's pywal16-full actually provides;
    # anything else would fail silently inside set-wal's `|| true` and leave a
    # stale palette behind
    assertions = [
      {
        assertion = builtins.elem cfg.darkBackend [
          "wal"
          "colorthief"
          "fast_colorthief"
          "modern_colorthief"
          "haishoku"
          "colorz"
        ];
        message = "frogix.pywal.darkBackend: '${cfg.darkBackend}' is not a backend pywal16-full ships (wal, colorthief, fast_colorthief, modern_colorthief, haishoku, colorz)";
      }
    ];

    home.packages = [
      set-wal
      rice-mode
    ];

    # periodic wallpaper shuffle — the knob is the interval; 0 means the
    # timer (and service) are never installed and the login shuffle is it
    systemd.user.services.wal-cycle = lib.mkIf (cfg.cycleInterval > 0) {
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "wal-cycle" ''
          ${set-wal}/bin/set-wal "$(find ${config.frogix.wallpapersDir} -type f | shuf -n 1)"
        ''}";
      };
    };

    systemd.user.timers.wal-cycle = lib.mkIf (cfg.cycleInterval > 0) {
      Timer = {
        OnBootSec = "${toString cfg.cycleInterval}min";
        OnUnitActiveSec = "${toString cfg.cycleInterval}min";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    # GTK recolor via home-manager's own extraCss slots — NOT manual
    # xdg.configFile gtk.css definitions. HM composes gtk-4.0/gtk.css as
    # (theme @import + extraCss), so the pywal override is guaranteed to load
    # AFTER the adw-gtk3-dark theme in cascade order. A competing manual
    # xdg.configFile."gtk-4.0/gtk.css" definition concatenates BEFORE the theme
    # import, which buries pywal (that was the bug) — never do that.
    # GTK3 layers ~/.config/gtk-3.0/gtk.css over the theme automatically.
    gtk.gtk3.extraCss = ''
      @import url("file://${walCache}/gtk-colors.css");
    '';
    gtk.gtk4.extraCss = ''
      @import url("file://${walCache}/gtk-colors.css");
    '';

    xdg.configFile = {

      # Real GTK recolor: maps pywal palette onto the GTK named colors that
      # adw-gtk3 actually uses (theme_bg_color etc.) plus the libadwaita/
      # adwaita vars (window_bg_color, accent_bg_color...). plain colors.css only
      # defines --colorN vars nothing references, which is why "gtk not following
      # pywal". Exported by wal to ~/.cache/wal/gtk-colors.css on every set-wal.
      "wal/templates/gtk-colors.css".text = ''
        /* Generated by pywal — GTK/adwaita named colors. Loads AFTER the theme. */
        @define-color theme_bg_color {background};
        @define-color theme_fg_color {foreground};
        @define-color theme_base_color {background};
        @define-color theme_text_color {foreground};
        @define-color theme_selected_bg_color {color1};
        @define-color theme_selected_fg_color {foreground};
        @define-color insensitive_bg_color {color0};
        @define-color insensitive_fg_color {color8};
        @define-color insensitive_base_color {color0};
        @define-color theme_unfocused_bg_color {background};
        @define-color theme_unfocused_fg_color {color8};
        @define-color theme_unfocused_base_color {color0};
        @define-color theme_unfocused_selected_bg_color {color8};
        @define-color borders {color8};
        @define-color unfocused_borders {color0};
        @define-color warning_color {color3};
        @define-color error_color {color1};
        @define-color success_color {color2};

        /* libadwaita / adw-gtk3 vars */
        @define-color accent_bg_color {color1};
        @define-color accent_fg_color {background};
        @define-color accent_color {color1};
        @define-color window_bg_color {background};
        @define-color window_fg_color {foreground};
        @define-color view_bg_color {background};
        @define-color view_fg_color {foreground};
        @define-color headerbar_bg_color {background};
        @define-color headerbar_fg_color {foreground};
        @define-color headerbar_border_color {color8};
        @define-color card_bg_color {color0};
        @define-color card_fg_color {foreground};
        @define-color popover_bg_color {color0};
        @define-color popover_fg_color {foreground};
        @define-color dialog_bg_color {background};
        @define-color dialog_fg_color {foreground};
        @define-color sidebar_bg_color {color0};
        @define-color sidebar_fg_color {foreground};

        /* vitrina polish — match the quickshell island */
        headerbar, .titlebar {
            box-shadow: none;
            border-bottom: 1px solid alpha(@accent_color, 0.22);
        }

        button, entry, spinbutton, dropdown, menubutton > button, .card {
            border-radius: 10px;
        }

        popover > contents, popover.background {
            border-radius: 12px;
            border: 1px solid alpha(@accent_color, 0.22);
        }

        *:selected, *:selected:focus {
            background-color: alpha(@accent_color, 0.30);
            color: @theme_fg_color;
        }

        tooltip, tooltip.background {
            border-radius: 8px;
            border: 1px solid alpha(@accent_color, 0.22);
        }
      '';

      # rofi palette for the "vitrina" rofi theme (modules/home-manager/rofi-vitrina.rasi).
      # rasi has no alpha() function, so the soft variants are hex + 2-digit alpha,
      # which rofi parses as #RRGGBBAA.
      "wal/templates/rofi-colors.rasi".text = ''
        /* Generated by pywal — rofi palette for the vitrina theme */
        * {
            vt-bg: {background};
            vt-bg0: {color0};
            vt-fg: {foreground};
            vt-accent: {color1};
            vt-accent2: {color2};
            vt-muted: {color8};
            vt-accent-3d: {color1}3d;
            vt-accent-45: {color1}45;
            vt-accent-26: {color1}26;
            vt-accent-14: {color1}14;
            vt-fg-0a: {foreground}0a;
            vt-fg-14: {foreground}14;
        }
      '';

      # vitrina lock screen (hyprlock). the whole config is templated because
      # hyprlock has no colour-only include: niri.nix symlinks
      # ~/.config/hypr/hyprlock.conf at ${walCache}/hyprlock.conf.
      "wal/templates/hyprlock.conf".text = ''
        # vitrina lock screen — generated by pywal
        $vt_bg = rgba({background.strip}f2)
        $vt_scrim = rgba({background.strip}9e)
        $vt_fg = rgba({foreground.strip}ff)
        $vt_muted = rgba({color8.strip}ff)
        $vt_accent = rgba({color1.strip}ff)
        $vt_accent_soft = rgba({color1.strip}45)
        $vt_font = Maple Mono NF

        general {
            hide_cursor = true
            ignore_empty_input = true
        }

        animations {
            enabled = true
            bezier = easeOutQuint, 0.23, 1, 0.32, 1
            animation = fadeIn, 1, 4, easeOutQuint
            animation = fadeOut, 1, 4, easeOutQuint
            animation = inputFieldDots, 1, 2, easeOutQuint
        }

        # side screens: plain black
        background {
            monitor =
            color = rgba(000000ff)
        }

        # main screen: the current wallpaper, untouched
        background {
            monitor = ${config.frogix.screens.main}
            path = {wallpaper}
            blur_passes = 0
        }

        # slight dim so the card separates from the wallpaper
        shape {
            monitor = ${config.frogix.screens.main}
            size = 100%, 100%
            color = $vt_scrim
            rounding = 0
            position = 0, 0
        }

        shape {
            monitor = ${config.frogix.screens.main}
            size = 470, 300
            color = $vt_bg
            rounding = 22
            border_size = 1
            border_color = rgba({color1.strip}66)
            position = 0, 0
        }

        label {
            monitor = ${config.frogix.screens.main}
            text = cmd[update:1000] date +"%H:%M"
            font_family = $vt_font
            font_size = 56
            color = $vt_fg
            position = 0, 62
        }

        label {
            monitor = ${config.frogix.screens.main}
            text = cmd[update:60000] date +"%A %-d %B"
            font_family = $vt_font
            font_size = 13
            color = rgba({foreground.strip}b3)
            position = 0, -6
        }

        input-field {
            monitor = ${config.frogix.screens.main}
            size = 340, 50
            position = 0, -84
            rounding = 12
            outline_thickness = 1
            inner_color = rgba({foreground.strip}0a)
            outer_color = $vt_accent_soft
            check_color = $vt_accent
            fail_color = rgba({color2.strip}ff)
            font_color = $vt_fg
            font_family = $vt_font
            placeholder_text = Password
            fade_on_empty = false
        }
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

      "wal/templates/vesktop.css".text =
        #css
        ''
          /* ═══════════════════════════════════════════════════════════════
             vitrina-material — a discord theme
             material shapes (flat cards, soft washes, one radius scale)
             + vitrina identity (pywal surfaces, color1 accent, ALLCAPS
             accent usernames, Cantarell, nerd glyphs via fallback).
             layout scaffolding: refact0r/midnight (design-token mapping).
             ═══════════════════════════════════════════════════════════════ */
          @import url('https://refact0r.github.io/midnight-discord/build/midnight.css');

          :root {
              --colors: on;

              /* proportional face; code + nerd glyphs keep the mono */
              --font: 'Cantarell';
              --code-font: 'Maple Mono NF';

              /* text */
              --text-0: {background};
              --text-1: {foreground};
              --text-2: {foreground};
              --text-3: {foreground};
              --text-4: {foreground};
              --text-5: {foreground};
              --text-link: var(--vt-accent);

              /* surfaces — one base, two raised steps, all opaque */
              --bg-1: {background};
              --bg-2: color-mix(in srgb, {color8} 10%, {background});
              --bg-3: color-mix(in srgb, {color8} 18%, {background});
              --bg-4: {background};
              --hover: {color8}1a;
              --active: {color8}33;
              --active-2: {color8}4d;
              --message-hover: {color8}14;

              /* one accent: color1, like every other vitrina surface */
              --vt-accent: {color1};
              --vt-accent-wash: {color1}26;
              --vt-accent-soft: {color1}45;
              --accent-1: {color1};
              --accent-2: {color1};
              --accent-3: {color1};
              --accent-4: {color2};
              --accent-5: {color2};
              --accent-new: {color1};
              --mention: linear-gradient(to right, {color1}26 40%, transparent);
              --mention-hover: linear-gradient(to right, {color1}1a 40%, transparent);
              --reply: linear-gradient(to right, {color1}26 40%, transparent);
              --reply-hover: linear-gradient(to right, {color1}1a 40%, transparent);

              /* status */
              --online: {color6};
              --dnd: {color1};
              --idle: {color5};
              --streaming: {color3};
              --offline: {color7};

              /* borders: hairlines, like the island */
              --border-light: var(--hover);
              --border: var(--active);
              --border-hover: var(--active);
              --button-border: {color8}1a;

              /* semantic ramps stay semantic */
              --red-1: {color9};   --red-2: {color1};   --red-3: {color1};   --red-4: {color1};   --red-5: {color1};
              --green-1: {color10}; --green-2: {color2}; --green-3: {color2}; --green-4: {color2}; --green-5: {color2};
              --blue-1: {color12};  --blue-2: {color1};  --blue-3: {color1};  --blue-4: {color1};  --blue-5: {color1};
              --yellow-1: {color11}; --yellow-2: {color3}; --yellow-3: {color3}; --yellow-4: {color3}; --yellow-5: {color3};
              --purple-1: {color13}; --purple-2: {color5}; --purple-3: {color5}; --purple-4: {color5}; --purple-5: {color5};

              /* ── material: one radius scale, flat elevation, tighter gaps ── */
              --radius-sm: 8px;
              --radius-md: 12px;
              --radius-lg: 16px;
              --gap: 10px;
              --border-thickness: 1px;
              --divider-thickness: 3px;
              --elevation-low: none;
              --elevation-medium: none;
              --elevation-high: none;
              --panel-backdrop-filter: none;
          }

          /* ── panels as flat cards: hairline border, no shadows ── */
          [class*="guilds_"],
          [class*="sidebarList_"],
          [class*="panels_"],
          [class*="chatContent_"],
          [class*="membersWrap_"],
          [class*="subtitleContainer_"],
          [class*="searchResultsWrap_"],
          [class*="peopleColumn_"],
          [class*="nowPlayingColumn_"] {
              border: var(--border-thickness) solid var(--border) !important;
          }

          /* the app canvas behind the cards */
          [class*="bg_"] {
              background: var(--bg-1) !important;
          }

          /* ── material states: soft accent washes, never solid fills ── */
          [class*="modeSelected"],
          [class*="modeSelected"]:hover {
              background: var(--vt-accent-wash) !important;
          }

          [class*="modeConnected"],
          [class*="modeUnread"] {
              background: var(--active) !important;
          }

          /* mention pill: wash, not solid */
          [class*="mentioned"] {
              background: var(--vt-accent-wash) !important;
          }
          [class*="mentioned"]:before {
              background: var(--vt-accent) !important;
          }

          /* ── embeds + code: quiet flat cards ── */
          [class*="embedFull"] {
              background: var(--bg-2) !important;
              border: 1px solid var(--border) !important;
              border-radius: var(--radius-sm) !important;
          }

          .markup code,
          [class*="markup"] code {
              background: var(--bg-3) !important;
              border-radius: 6px !important;
          }

          /* ── scrollbars: 4px, rounded, quiet ── */
          ::-webkit-scrollbar {
              width: 4px;
              height: 4px;
          }
          ::-webkit-scrollbar-thumb {
              background: var(--active);
              border-radius: 2px;
          }
          ::-webkit-scrollbar-track {
              background: transparent;
          }

          /* ── tooltips: small flat cards ── */
          [class*="tooltip"] {
              background: var(--bg-3) !important;
              border: 1px solid var(--border);
              border-radius: var(--radius-sm) !important;
              box-shadow: none !important;
          }

          /* ── inputs: soft surface, accent focus ring ── */
          [class*="searchBar"],
          [class*="attachWrapper"],
          [class*="channelTextArea"] {
              border-radius: var(--radius-md) !important;
          }

          /* ── vitrina: ALLCAPS accent usernames and detail headers ── */
          [class*="username"],
          [class*="nickname"],
          [class*="nameTag"] span {
              text-transform: uppercase !important;
              color: var(--vt-accent) !important;
              font-weight: 600;
          }

          [class*="membersGroup"],
          [class*="timestamp"] {
              text-transform: uppercase;
              color: var(--vt-accent) !important;
              letter-spacing: 0.03em;
          }

          /* channel categories: caps + muted, like the island headers */
          [class*="containerDefault"] [class*="name_"] {
              text-transform: uppercase;
              letter-spacing: 0.04em;
          }

          /* ── portrait-friendly: the channel / DM list collapses to a rail and
             OVERLAPS the chat when open — the chat never reflows. exact classes
             from midnight's build-pinned selectors ── */

          /* the group is overflow:hidden and only as wide as the collapsed rail
             (guilds + 14px), so it CLIPS the expanded list at its edge — the list
             was expanding all along, just invisible. unclip + lift above the chat */
          .sidebar_pog62O {
              overflow: visible !important;
              position: relative;
              /* above the chat (z-auto), BELOW discord's modal/lightbox layer
                 (z 1002) — 9999 here put the rail over the image lightbox */
              z-index: 100;
          }

          .sidebarList_pog62O {
              position: relative;
              z-index: 10;
              /* static geometry: layout never changes, the reveal is clip-only
                 (compositor) — animating width reflows the virtualized channel
                 tree every frame and stutters */
              width: min(50vw, 480px) !important;
              min-width: 14px !important;
              margin-right: calc(14px - min(50vw, 480px)) !important;
              overflow: hidden !important;
              border-left: 2px solid var(--vt-accent-soft) !important;
              clip-path: inset(0 calc(100% - 14px) 0 0);
              transition: clip-path 0.18s ease;
          }

          /* the real resize bar is sidebarResizeHandle_pog62O and it sits ON the
             rail's right edge, stealing the hover — let the rail take it back */
          .sidebarResizeHandle_pog62O {
              pointer-events: none !important;
          }

          /* open on any part of the sidebar group: guilds, the gutter between
             panels, the rail — the group box covers them all */
          .sidebar_pog62O:hover .sidebarList_pog62O {
              clip-path: inset(0 0 0 0);
          }

          /* the user panel (pfp + mute/deafen/settings) is a SIBLING of the list
             and its icon row is wider than the collapsed rail. hidden completely
             when closed (visibility beats the !important card border shorthand),
             grows back in lockstep with the list on hover */
          .panels_pog62O {
              overflow: hidden !important;
              max-height: 0 !important;
              visibility: hidden;
              /* static geometry, same as the list — only height animates */
              width: calc(min(50vw, 480px) + 78px) !important;
              margin-right: calc(14px - min(50vw, 480px)) !important;
              transition: max-height 0.18s ease;
          }

          .sidebar_pog62O:hover .panels_pog62O {
              visibility: visible;
              max-height: 200px !important;
          }
        '';
      # qt5ct / qt6ct palette (fusion style + custom colors).
      # exported by wal to ~/.cache/wal/qt-colors.conf on every set-wal run,
      # then symlinked into both qt5ct/colors/ and qt6ct/colors/ below.
      # 21 entries = qpalette roles: windowtext, button, light, midlight,
      # dark, mid, text, brighttext, buttontext, base, window, shadow,
      # highlight, highlightedtext, link, linkvisited, alternatebase,
      # norole, tooltipbase, tooltiptext, placeholdertext.
      "wal/templates/qt-colors.conf".text = ''
        [ColorScheme]
        active_colors={foreground}, {color0}, {color8}, {color8}, {color0}, {color8}, {foreground}, {color15}, {foreground}, {background}, {background}, {color0}, {color1}, {background}, {color6}, {color5}, {color0}, {background}, {color0}, {foreground}, {color8}
        disabled_colors={color8}, {color0}, {color8}, {color8}, {color0}, {color8}, {color8}, {color15}, {color8}, {background}, {background}, {color0}, {color8}, {color8}, {color8}, {color8}, {color0}, {background}, {color0}, {color8}, {color8}
        inactive_colors={foreground}, {color0}, {color8}, {color8}, {color0}, {color8}, {foreground}, {color15}, {foreground}, {background}, {background}, {color0}, {color1}, {background}, {color6}, {color5}, {color0}, {background}, {color0}, {foreground}, {color8}
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

          (defvar frogix/font-reloaded nil)

          (defun frogix/apply-pywal-theme-to-frame (frame)
            (with-selected-frame frame
              (unless frogix/font-reloaded
                (setq frogix/font-reloaded t)
                (doom/reload-font))
              (frogix/apply-pywal-theme)))
          (add-hook 'after-make-frame-functions #'frogix/apply-pywal-theme-to-frame)
          (add-hook 'doom-load-theme-hook #'frogix/apply-pywal-theme)

          (when doom-theme
            (run-hooks 'doom-load-theme-hook))

        '';

      "emacs/pywal.el".source = config.lib.file.mkOutOfStoreSymlink "${walCache}/emacs.el";
      "vesktop/themes/custom.css" = lib.mkIf config.frogix.vesktop.enable {
        source = config.lib.file.mkOutOfStoreSymlink "${walCache}/vesktop.css";
      };
      "hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink "${walCache}/hyprlock.conf";

      # qt reads its palette at app startup, so symlink the wal output
      # straight in. no set-wal hook change needed, just relaunch qt apps.
      "qt5ct/colors/pywal.conf".source = config.lib.file.mkOutOfStoreSymlink "${walCache}/qt-colors.conf";
      "qt6ct/colors/pywal.conf".source = config.lib.file.mkOutOfStoreSymlink "${walCache}/qt-colors.conf";

      # point both qt config tools at fusion + the pywal scheme above.
      "qt5ct/qt5ct.conf".text = ''
        [Appearance]
        style=fusion
        icon_theme=Papirus-Dark
        custom_palette=true
        color_scheme_path=${config.home.homeDirectory}/.config/qt5ct/colors/pywal.conf
        [Fonts]
        general="Maple Mono NF,10,-1,5,50,0,0,0,0,0"
        fixed="Maple Mono NF,10,-1,5,50,0,0,0,0,0"
      '';
      "qt6ct/qt6ct.conf".text = ''
        [Appearance]
        style=fusion
        icon_theme=Papirus-Dark
        custom_palette=true
        color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/pywal.conf
        [Fonts]
        general="Maple Mono NF,10,-1,5,50,0,0,0,0,0"
        fixed="Maple Mono NF,10,-1,5,50,0,0,0,0,0"
      '';
    };

    home.activation.seedPywal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${walCache}"
      if [ ! -e "${walCache}/colors.sh" ]; then
        # the seed is mode-aware so a dark-mode host never boots with a wal
        # palette: light seeds with wal -l, dark seeds with darkBackend (the
        # first set-wal regenerates both from the real wallpaper anyway).
        verboseEcho "Seeding pywal cache from the bundled wallpaper"
        seed_mode="dark"
        if [ -r "${riceModeFile}" ]; then
          seed_mode="$(tr -d '[:space:]' < "${riceModeFile}")"
        fi
        if [ "$seed_mode" = "light" ]; then
          run env -i HOME="$HOME" TERM=xterm-256color ${pywal16-full}/bin/wal --backend wal -l -i ${./wallpaper.png} -n -q || true
        else
          run env -i HOME="$HOME" TERM=xterm-256color ${pywal16-full}/bin/wal --backend ${cfg.darkBackend} -i ${./wallpaper.png} -n -q || true
        fi
      else
        verboseEcho "Refreshing pywal templates from the existing cache"
        run env -i HOME="$HOME" TERM=xterm-256color ${pywal16-full}/bin/wal -R -n -q || true
      fi
      # niri refuses to start if its included file is missing — wal can fail
      # here (rebuild from a foreign terminal, headless switch), so land a
      # neutral fallback before the first session ever runs.
      if [ ! -e "${walCache}/niri-colors.kdl" ]; then
        verboseEcho "Writing neutral niri colors fallback"
        run cp ${niriColorsFallback} "${walCache}/niri-colors.kdl"
      fi
    '';

    # an empty wallpapers dir means set-wal has nothing to pick and vitrina
    # waits on colors.json forever. copy the bundled wallpaper in while the
    # dir holds no files — hosts with a real collection (ratholomew's
    # /storage/Walls) or a deliberately deleted wallpaper.png stay untouched.
    home.activation.seedWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${config.frogix.wallpapersDir}"
      if [ -z "$(find "${config.frogix.wallpapersDir}" -type f -print -quit)" ]; then
        verboseEcho "Seeding wallpapers dir with the bundled wallpaper"
        run cp "${./wallpaper.png}" "${config.frogix.wallpapersDir}/wallpaper.png"
      fi
    '';

  };
}
