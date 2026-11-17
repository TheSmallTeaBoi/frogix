{
  config,
  lib,
  pkgs,
  nixosConfig ? null,
  ...
}:
let
  cfg = config.frogix.vitrina;

  # brightness via DDC/CI (this box has no sysfs backlight — brightnessctl
  # was adjusting a scrolllock led). the shadow value file drives the
  # vitrina OSD; setvcp runs async so the keys feel instant.
  vitrina-bright = pkgs.writeShellApplication {
    name = "vitrina-bright";
    runtimeInputs = [ pkgs.ddcutil ];
    text = ''
      f=/run/user/$(id -u)/vitrina-bright
      if [ -s "$f" ]; then
        v=$(cat "$f")
      else
        v=$(ddcutil getvcp 10 --brief 2>/dev/null | awk '{print $4}' | head -1)
        case "$v" in ""|*[!0-9]*) v=50;; esac
      fi
      case "$1" in
        up) v=$((v + 10));;
        down) v=$((v - 10));;
      esac
      [ "$v" -gt 100 ] && v=100
      [ "$v" -lt 0 ] && v=0
      ddcutil setvcp 10 "$v" >/dev/null 2>&1 &
      printf '%s' "$v" > "$f"
    '';
  };

  # night light switch: toggles the wlsunset user unit, then reports the
  # real unit state to the island via the flag file
  vitrina-nightlight = pkgs.writeShellApplication {
    name = "vitrina-nightlight";
    text = ''
      f=/run/user/$(id -u)/vitrina-nightlight
      if systemctl --user is-active --quiet wlsunset; then
        systemctl --user stop wlsunset
        rm -f "$f"
      else
        systemctl --user start wlsunset
        touch "$f"
      fi
    '';
  };

  # lock the session, idempotently, and only return once hyprlock is up.
  # niri does not implement hyprland-lock-notify-v1, so hypridle cannot wait
  # for the locker before sleep; this is used as its before_sleep_cmd and by
  # the island's suspend action.
  vitrina-lock = pkgs.writeShellApplication {
    name = "vitrina-lock";
    runtimeInputs = with pkgs; [
      hyprlock
      procps
      coreutils
    ];
    text = ''
      if ! pidof hyprlock >/dev/null 2>&1; then
        hyprlock --no-fade-in >/dev/null 2>&1 &
      fi
      for _ in $(seq 1 150); do
        pidof hyprlock >/dev/null 2>&1 && break
        sleep 0.02
      done
      # let hyprlock paint the lock surface before we report success
      sleep 0.5
    '';
  };

  # lock first, then suspend. Deterministic on niri where hypridle's sleep
  # inhibitor can't guarantee the lock is drawn before the machine sleeps.
  vitrina-lock-suspend = pkgs.writeShellApplication {
    name = "vitrina-lock-suspend";
    runtimeInputs = [
      vitrina-lock
      pkgs.systemd
    ];
    text = ''
      vitrina-lock
      systemctl suspend
    '';
  };

  # screen recorder front-end around gpu-screen-recorder. Records the main
  # monitor (FROGIX_MAIN_SCREEN, falling back to the first monitor) with
  # desktop audio and an optional microphone, and keeps enough state in a
  # runtime file for the island to show status + elapsed time.
  vitrina-record = pkgs.writeShellApplication {
    name = "vitrina-record";
    runtimeInputs = with pkgs; [
      gpu-screen-recorder
      coreutils
    ];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/vitrina-record"
      outdir="''${XDG_VIDEOS_DIR:-$HOME/Videos}"
      monitor="''${FROGIX_MAIN_SCREEN:-}"

      recording() {
        [ -s "$state" ] || return 1
        read -r pid _ < "$state" || return 1
        kill -0 "$pid" 2>/dev/null
      }

      start() {
        if recording; then
          echo "already-recording"
          return 0
        fi
        mic=0
        audio=1
        while [ $# -gt 0 ]; do
          case "$1" in
            --monitor) shift; monitor="''${1:-$monitor}" ;;
            --mic) mic=1 ;;
            --no-audio) audio=0 ;;
          esac
          shift
        done
        if [ -z "$monitor" ]; then
          monitor="$(gpu-screen-recorder --list-monitors 2>/dev/null | head -n1 | cut -d'|' -f1)"
        fi
        [ -n "$monitor" ] || { echo "no monitor found" >&2; exit 1; }
        mkdir -p "$outdir"
        file="$outdir/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
        args=(gpu-screen-recorder -w "$monitor" -f 60 -o "$file")
        if [ "$audio" = 1 ]; then
          args+=(-a default_output)
          if [ "$mic" = 1 ]; then
            args+=(-a default_input)
          fi
        fi
        nohup "''${args[@]}" >"$state.log" 2>&1 &
        printf '%s %s %s\n' "$!" "$(date +%s)" "$file" > "$state"
        echo "started $file"
      }

      stop() {
        if ! recording; then
          rm -f "$state"
          echo "idle"
          return 0
        fi
        read -r pid _ _ < "$state"
        kill -INT "$pid" 2>/dev/null || true
        for _ in $(seq 1 60); do
          kill -0 "$pid" 2>/dev/null || break
          sleep 0.1
        done
        rm -f "$state"
        echo "stopped"
      }

      status() {
        if recording; then
          read -r _ start file < "$state"
          echo "recording $(( $(date +%s) - start )) $file"
        else
          rm -f "$state"
          echo "idle"
        fi
      }

      cmd="''${1:-status}"
      shift 2>/dev/null || true
      case "$cmd" in
        start) start "$@" ;;
        stop) stop ;;
        toggle)
          if recording; then stop; else start "$@"; fi
          ;;
        status) status ;;
        *)
          echo "usage: vitrina-record start|stop|toggle|status" >&2
          exit 2
          ;;
      esac
    '';
  };

  # the music player and editor are nixos-side choices (frogix.packages and
  # frogix.shell), read through nixosConfig; standalone home-manager eval (the
  # docs pass) has no nixosConfig, and the emacs area is the editor fallback.
  music =
    if nixosConfig != null && nixosConfig.frogix.packages.music then
      nixosConfig.frogix.packages.musicPlayer
    else
      null;

  editor =
    if nixosConfig != null && nixosConfig.frogix.shell.editor != null then
      nixosConfig.frogix.shell.editor
    else if config.frogix.emacs.enable then
      "emacsclient -c"
    else
      null;

  item = key: label: { inherit key label; };

  # the hotkey cheatsheet is generated here (not hardcoded in shell.qml) so it
  # only lists binds whose area is actually on. keep it in sync with the binds
  # in modules/home-manager/niri.nix.
  hotkeyGroups = [
    {
      name = "apps";
      items = [
        (item "mod+d" "App Launcher")
        (item "mod+b" "Browser")
      ]
      ++ lib.optionals config.frogix.kitty.enable [
        (item "mod+enter" "Terminal")
      ]
      ++ lib.optionals (editor != null) [
        (item "mod+o" "Editor")
      ]
      ++ [ (item "mod+e" "Files") ]
      ++ lib.optionals (music != null) [
        (item "mod+l" "Music Player")
      ]
      ++ [
        (item "mod+r" "Clipboard")
        (item "mod+c" "Calculator")
        (item "mod+." "Emoji")
      ];
    }
    {
      name = "windows";
      items = [
        (item "mod+t" "Close Window")
        (item "mod+w" "Window Switcher")
        (item "mod+f" "Fullscreen")
        (item "mod+s" "Maximize")
        (item "mod+p" "Float")
        (item "mod+j / mod+k" "Focus Down / Up")
        (item "mod+left / mod+right" "Focus Column")
        (item "mod+shift+left / mod+shift+right" "Move Column")
        (item "mod+shift+j / mod+shift+k" "Move Down / Up")
        (item "mod+[ / mod+]" "Consume / Expel")
        (item "mod+minus / mod+=" "Column Width")
        (item "mod+tab / mod+`" "Monitor Next / Prev")
        (item "mod+ctrl+tab / mod+ctrl+`" "Move To Monitor")
      ];
    }
    {
      name = "workspaces";
      items = [
        (item "mod+1..9" "Focus Workspace")
        (item "mod+ctrl+1..9" "Move To Workspace")
        (item "mod+pgup / mod+pgdn" "Workspace Up / Down")
        (item "mod+ctrl+pgup / mod+ctrl+pgdn" "Move Up / Down")
        (item "super+wheel" "Switch Workspace / Column")
      ];
    }
    {
      name = "system";
      items = [
        (item "print" "Screenshot")
        (item "shift+print" "Screen To Clipboard")
        (item "ctrl+print" "Window To Clipboard")
        (item "super+shift+print" "Screen To Disk")
        (item "super+ctrl+print" "Window To Disk")
      ]
      ++ lib.optionals config.frogix.pywal.enable [
        (item "mod+shift+w" "Next Wallpaper")
        (item "mod+shift+l" "Rice Mode")
      ]
      ++ [
        (item "mod+n" "Night Light")
        (item "xf86audioplay" "Play / Pause")
        (item "xf86audionext / xf86audioprev" "Player Next / Prev")
        (item "xf86audioraisevolume / xf86audiolowervolume" "Volume Up / Down")
        (item "xf86audiomute" "Sink Mute")
        (item "xf86audiomicmute / f17" "Mic Mute")
        (item "xf86monbrightnessup / down" "Brightness")
        (item "mod+shift+/" "This Reminder")
      ];
    }
  ];

  hotkeysJson = pkgs.writeText "vitrina-hotkeys.json" (builtins.toJSON hotkeyGroups);
in
{
  options.frogix."vitrina".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "quickshell shell packages + config";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables.FROGIX_MAIN_SCREEN = config.frogix.screens.main;
    home.packages = [
      pkgs.quickshell
      pkgs.playerctl
      pkgs.pulseaudio
      pkgs.ddcutil
      pkgs.wlsunset
      pkgs.libqalculate
      vitrina-bright
      vitrina-nightlight
      vitrina-lock
      vitrina-lock-suspend
      vitrina-record
    ];

    # keep libqalculate's exchange-rate cache fresh so the launcher's qalc
    # calls never block on a network fetch mid-query
    systemd.user.services.qalculate-exrates = {
      Unit.Description = "Refresh qalculate exchange rates";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.libqalculate}/bin/qalc -e -t --color=0 -- 1";
      };
    };

    systemd.user.timers.qalculate-exrates = {
      Unit.Description = "Daily qalculate exchange rate refresh";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

    # night light: unit exists but never autostarts — the island toggle
    # (or systemctl --user start wlsunset) owns it. coords: cordoba.
    systemd.user.services.wlsunset = {
      Unit.Description = "Night light (color temperature schedule)";
      Service = {
        ExecStart = "${pkgs.wlsunset}/bin/wlsunset -l -31.42 -L -64.18";
        Restart = "on-failure";
      };
    };

    xdg.configFile."vitrina" = {
      # ship the static qml plus the generated hotkey cheatsheet as one dir
      source = pkgs.runCommand "vitrina-config" { } ''
        cp -r ${./vitrina} $out
        chmod -R u+w $out
        cp ${hotkeysJson} $out/hotkeys.json
      '';
      recursive = true;
    };

    # emoji search dataset, shared with rofi-emoji so both stay in sync
    xdg.dataFile."vitrina/emojis.txt".source = "${pkgs.rofi-emoji}/share/rofi-emoji/all_emojis.txt";
  };
}
