{
  pkgs,
  ...
}:
# github.com/12errh/zen-proxy — local OpenAI-compatible proxy that re-exposes
# opencode.ai's free Zen tier (injects the opencode User-Agent upstream).
let
  zen-proxy-upstream = pkgs.fetchFromGitHub {
    owner = "12errh";
    repo = "zen-proxy";
    rev = "8dcf4b6c1b275059aef4e46ef65bb75828d211f9"; # 2026-09-09
    hash = "sha256-Ne0+pjo/poznUmoS8n+07nmWTyO2YeCkhXCJXjUZ8ZI=";
  };
  # Upstream ties streamed upstream fetches to the downstream req.signal,
  # which fires immediately here and aborts every streamed request in ms
  # (hermes always streams).
  # Use the timeout signal for both paths instead. FIXME Re-check on update.
  zen-proxy-src = pkgs.stdenvNoCC.mkDerivation {
    name = "zen-proxy-patched";
    src = zen-proxy-upstream;
    phases = [
      "unpackPhase"
      "patchPhase"
      "installPhase"
    ];
    patchPhase = ''
      substituteInPlace zen-proxy.mjs --replace-fail \
        'signal: isStream ? req.signal : AbortSignal.timeout(config.timeoutMs),' \
        'signal: AbortSignal.timeout(config.timeoutMs),'
      # This instance serves the ANONYMOUS free pool only: never forward client
      # credentials upstream. Hermes attaches unrelated pool keys as Bearer,
      # which zen rejects with 401 "Invalid API key".
      substituteInPlace zen-proxy.mjs --replace-fail \
        'if (incoming && incoming !== "public") return `Bearer ''${incoming}`' \
        'if (false) return `Bearer ''${incoming}`'
    '';
    installPhase = "cp -r . $out";
  };
  port = 8787;
in
{
  systemd.services.zen-proxy = {
    description = "zen-proxy (opencode free-tier bridge for hermes, localhost only)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    environment = {
      HOST = "127.0.0.1";
      PORT = toString port;
      DEFAULT_MODEL = "mimo-v2.5-free";
      FALLBACK_MODELS = builtins.toJSON [
        "hy3-free"
        "nemotron-3-ultra-free"
        "nemotron-3.5-lightning-free"
        "laguna-s-2.1-free"
        "ling-3.0-flash-fin-free"
        "big-pickle"
      ];
    };
    serviceConfig = {
      ExecStart = "${pkgs.nodejs}/bin/node ${zen-proxy-src}/zen-proxy.mjs";
      Restart = "always";
      RestartSec = "3s";
      DynamicUser = true;
      StateDirectory = "zen-proxy";
      WorkingDirectory = "/var/lib/zen-proxy";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };
}
