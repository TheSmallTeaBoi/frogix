{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.sunshine;
  launch-gamescope = pkgs.writeShellApplication {
    name = "launch-gamescope";

    runtimeInputs = with pkgs; [
      gamescope
      steam
      procps
      coreutils
      jq
      pkgs.niri
    ];

    text = ''
      export XDG_SESSION_TYPE=wayland
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
      export ENABLE_GAMESCOPE_WSI=1

      # Sunshine must be spawned from inside the session so it inherits
      # WAYLAND_DISPLAY; refuse to run with a dead socket.
      if [ ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
          echo "Wayland socket $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY not found" >&2
          exit 1
      fi

      # Needed for `niri msg` if it wasn't imported into the environment
      if [ -z "''${NIRI_SOCKET:-}" ]; then
          for sock in "$XDG_RUNTIME_DIR"/niri.*.sock; do
              if [ -S "$sock" ]; then
                  NIRI_SOCKET="$sock"
                  break
              fi
          done
          export NIRI_SOCKET
      fi

      # Steam doesn't like a second instance competing
      pkill -x steam 2>/dev/null || true

      gamescope \
          -e -f \
          -w 1920 -h 1080 --nested-refresh 120 \
          -W 1920 -H 1080 -r 120 \
          -F nearest \
          --force-composition \
          -- steam \
          -gamepadui \
          -width 1920 -height 1080 \
          -pipewire-dmabuf &
      GS_PID=$!
      trap 'kill "$GS_PID" 2>/dev/null' INT TERM

      # Place our window fullscreen on the main monitor. Done from here
      # instead of window rules so regular local gamescope instances are
      # left alone.
      # gamescope only maps its toplevel once steam draws something, and a
      # cold steam bootstrap can take a while, so poll for up to 2 minutes.
      WIN_ID=""
      for _ in $(seq 1 600); do
          WIN_ID="$(niri msg --json windows 2>/dev/null \
              | jq -r --argjson pid "$GS_PID" \
                  '[.[] | select(."app_id" == "gamescope" and .pid == $pid)] | first | .id // empty' \
              || true)"
          if [ -z "$WIN_ID" ]; then
              WIN_ID="$(niri msg --json windows 2>/dev/null \
                  | jq -r '[.[] | select(."app_id" == "gamescope")] | first | .id // empty' \
                  || true)"
          fi
          if [ -n "$WIN_ID" ]; then
              break
          fi
          sleep 0.2
      done

      if [ -n "$WIN_ID" ]; then
          # Land it fullscreen on DP-3's currently active workspace.
          # focus-monitor first so the workspace index resolves against DP-3.
          WS_IDX="$(niri msg --json workspaces 2>/dev/null \
              | jq -r '[.[] | select(.output == "${cfg.output}" and .is_active)] | first | .idx // empty' \
              || true)"
          niri msg action focus-monitor ${cfg.output} || true
          niri msg action focus-window --id "$WIN_ID" || true
          if [ -n "$WS_IDX" ]; then
              niri msg action move-window-to-workspace "$WS_IDX" || true
              niri msg action focus-workspace "$WS_IDX" || true
          fi
          niri msg action fullscreen-window --id "$WIN_ID" || true
      else
          echo "gamescope window never showed up, leaving it where it spawned" >&2
      fi

      wait "$GS_PID"
    '';
  };
in
{
  options.frogix.sunshine = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "sunshine game streaming with the gamescope launcher";
    };
    output = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "monitor sunshine captures (null = sunshine auto-detects)";
    };
  };

  config = lib.mkIf cfg.enable {
    # sunshine.conf and apps.json are deliberately NOT managed: sunshine
    # generates and then rewrites both at runtime, and managing them just
    # produces backup-file churn on every switch. the launcher stays on PATH
    # so a hand-maintained apps.json can reference it by name.
    home.packages = [ launch-gamescope ];
  };
}
