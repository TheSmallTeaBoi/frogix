{
  config,
  lib,
  pkgs,
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
in
{
  options.frogix."vitrina".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "quickshell shell packages + config";
  };

  options.frogix."vitrina".searchRoots = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "/storage/Personal" ];
    description = ''
      extra directories the launcher's file search scans, in addition to
      $HOME. host-specific, so it has no default.
    '';
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      FROGIX_MAIN_SCREEN = config.frogix.screens.main;
      # colon-separated; read by vitrina's file-search process
      FROGIX_SEARCH_ROOTS = lib.concatStringsSep ":" cfg.searchRoots;
    };
    home.packages = [
      pkgs.quickshell
      pkgs.playerctl
      pkgs.pulseaudio
      pkgs.ddcutil
      pkgs.wlsunset
      pkgs.fd
      vitrina-bright
      vitrina-nightlight
      vitrina-lock
      vitrina-lock-suspend
      vitrina-record
    ];

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
      source = ./vitrina;
      recursive = true;
    };

    # emoji search dataset, shared with rofi-emoji so both stay in sync
    xdg.dataFile."vitrina/emojis.txt".source = "${pkgs.rofi-emoji}/share/rofi-emoji/all_emojis.txt";
  };
}
