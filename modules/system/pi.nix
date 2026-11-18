{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.frogix.pi;
  frogixUser = config.frogix.user;

  # pi-bg-handoff reads its config from <agentDir>/pi-bg-handoff.json or the
  # path in PI_BG_HANDOFF_CONFIG (read once per load, never written back), so a
  # read-only store file is enough — no need to plant anything in ~/.pi/agent.
  # windowSeconds is the foreground probe: a bash call still running after this
  # long is handed off to a background task instead of being killed. the other
  # timeout (taskTimeoutSeconds, default 4h) stays untouched.
  bgHandoffConfig = pkgs.writeText "pi-bg-handoff.json" (
    builtins.toJSON {
      windowSeconds = 60;
    }
  );

  # anthropics/skills' frontend-design skill — instructions only (one SKILL.md,
  # no scripts or components), so it is passed to pi as a plain --skill path.
  # pinned by rev+hash like the other external sources in this repo; refresh by
  # re-running
  #   nix-prefetch-url --unpack https://github.com/anthropics/skills/archive/<rev>.tar.gz
  # and swapping rev/hash. nothing to remove: it only shapes design choices
  # (palette, type, layout) and needs no upstream patch.
  anthropicSkills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "e4bb5d960d87126ff3b3a8af1a104b7db67560ba";
    hash = "sha256-Gr9LatjawHHK9uKpoclWoiDHZ0NTpP3/4Pmeatl8p/Q=";
  };
  frontendDesignSkill = "${anthropicSkills}/skills/frontend-design";

  # the wrapper binary pi.nix builds around the raw package (merges settings,
  # sources the sops dotenv, passes rules/skills/extensions). the desktop
  # entry below must launch this one — through piPicker below, not the bare
  # package — or the shared provider setup silently stops applying when pi is
  # started from a launcher.
  piWrapped = config.programs.pi.coding-agent.finalPackage;

  # the directory picker the desktop entry runs before pi: fzf's directory
  # walker over the frogix user's whole home (any directory is fair game, not
  # just git repos), fuzzy-search with a contents preview. a pi session is
  # pinned to the directory it starts in, so the choice has to happen before
  # launch; esc exits without starting pi and kitty then closes the window.
  # walker matches come back home-relative with a trailing slash (verified on
  # fzf 0.75), so a plain relative cd lands in the pick.
  piPicker = pkgs.writeShellApplication {
    name = "pi-picker";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fzf
      pkgs.git
    ];
    text = ''
      home="${config.users.users.${frogixUser}.home}"
      cd "$home"

      selection=$(
        fzf --walker=dir,follow --height=100% --layout=reverse --border \
            --header='pi · pick a directory (esc cancels)' \
            --preview='git -C {} log --oneline -8 2>/dev/null || ls -A --group-directories-first --color=always {}' \
            --preview-window=right:55%:wrap
      ) || exit 0
      [ -n "$selection" ] || exit 0

      cd "$selection"
      exec ${lib.getExe piWrapped}
    '';
  };

  # pi-web-access keeps its settings in <agentDir>/web-search.json — a file the
  # pi wrapper does not merge, unlike settings.json/mcp.json. it also can't be a
  # store symlink: the extension rewrites the file itself at runtime when a
  # provider or curator workflow is picked (saveConfig), and the store is
  # read-only. so the module renders the file and merges it over whatever is on
  # disk at activation, the same jq merge the wrapper does for settings.json:
  # the knobs below win, runtime keys (chosen provider, workflow, browser
  # cookies) survive.
  webSearchConfig = pkgs.writeText "pi-web-search.json" (builtins.toJSON cfg.webSearch);
in
{
  # pi — earendil-works' terminal coding agent via lukasl-dev/pi.nix (input
  # declared in flake.nix). imported here, not in flake.nix's hostModules,
  # so this file is the one self-contained place that defines pi on every
  # machine: flip its defaults below and the whole suite changes pi at once.
  # a host overrides per-machine values through frogix.pi.*; anything this
  # module has no knob for (jail, mcp, ...) is set as programs.pi.coding-agent.*
  # directly in the host.
  imports = [ inputs.pi.nixosModules.default ];

  options.frogix.pi = {
    # deliberate break from the default-to-frogix.enable contract: pi is not
    # universal infrastructure — it installs an agent wired to a personal
    # provider and a sops-sourced api key that only exists in the shared
    # secrets.yaml. defaulting on would key every fresh host (and the vm
    # template, which cannot decrypt that secret at all) to it. hosts opt IN
    # with frogix.pi.enable = true and get the identical shared setup.
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "pi coding agent with its shared setup and binary cache";
    };

    cache = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          add pi.nix's cachix substituters and signing keys to nix.settings.
          upstream ships them only as flake nixConfig, which nix ignores
          without --accept-flake-config — declared here the agent builds from
          the cache with no flags on any host that imports frogix
        '';
      };
    };

    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "hermes_env";
      description = ''
        name of a sops secret holding a KEY=VALUE dotenv that is sourced
        (set -a) into pi's environment on every launch. defaults to
        hermes_env, which carries SURPLUS_API_KEY — the key the surplus
        provider extension interpolates at request time — along with other
        now-retired hermes vars that pi simply ignores. the module declares
        the secret owned by frogix.user so the invoking user can read it;
        exclusive with the secrets knob
      '';
    };

    rules = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.lines lib.types.path);
      default = "Verify work before declaring it working or done. Never 'recall', investigate using your tools.";
      description = ''
        shared instructions appended to pi's system prompt on every machine
        (upstream passes them via --append-system-prompt). edit here to
        change pi everywhere; a host may override with its own text or a
        path to a rules file
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {
        defaultProvider = "surplus";
        defaultModel = "deepseek-v4.1-flash";
        # `system` samples the live terminal palette: kitty's palette itself
        # comes from pywal's colors-kitty.conf template, so the TUI still
        # tracks the wallpaper through the terminal. the dedicated pywal theme
        # file (wal template + ~/.pi/agent/themes symlink) is gone — one color
        # pipeline (kitty's) instead of two that could disagree.
        theme = "system";
        # pi packages (extensions/skills/etc as one unit): pi-web-access
        # from the pi.dev gallery — web search + fetch tools for the agent.
        # pi installs npm sources on startup, no store-pinning needed here
        packages = [
          "npm:pi-web-access"
          # single-agent delegation + scripted multi-agent workflows
          # (ships its own skills/ and prompts/ alongside the extension)
          "npm:pi-subagents"
          # vision: delegates image analysis only when the active model is
          # text-only; passes images straight through on multimodal models
          "npm:@getpipher/vision"
          # bg-handoff: moves long-running bash calls to background tasks, adds
          # host-side wait tools + the background-commands skill. its 60s probe
          # window comes from bgHandoffConfig below (frogix.pi.env)
          "npm:pi-bg-handoff"
          # openui: render_widget draws interactive dashboards, charts, diagrams
          # and maps inline in the TUI via OpenUI Lang — no browser, no network
          "npm:pi-openui"
          # open-tui: polished header/footer, framed editor, git + telemetry
          # status, compact tool rows, thinking peek and fullscreen copy
          # buttons. settings live in ~/.pi/agent/open-tui.json via /open-tui;
          # replaces the pretty-tui package (one TUI renderer at a time)
          "npm:pi-open-tui"
          # rpiv-ask-user-question: registers the ask_user_question tool, a
          # structured questionnaire (typed options, multi-select, optional
          # external-editor answer) the model can put to the user instead of
          # guessing on underspecified requests
          "npm:@juicesharp/rpiv-ask-user-question"
          # guardrails: .env/secret-file policies, out-of-workspace path access
          # and dangerous-command confirmation, as four extensions (guardrails,
          # path-access, permission-gate, herdr). registers no tools — only
          # tool_call hooks and guardrails:* commands, so it cannot collide with
          # the tool names above. the wrapper merges only settings.json/mcp.json
          # into the agent dir, so its state file
          # (~/.pi/agent/extensions/guardrails.json, written by
          # /guardrails:settings) stays user-owned: configure once with
          # /guardrails:onboarding. defaults keep pathAccess off; note that
          # in a headless run (pi -p, subagents) permission-gate BLOCKS
          # dangerous commands instead of prompting — allow-list those with
          # /guardrails:settings if scripted runs need them
          "npm:@aliou/pi-guardrails"
        ];
      };
      description = ''
        shared contents of pi's settings.json, recursively merged into
        ~/.pi/agent/settings.json on each invocation. defaults to starting
        every machine on the surplus intelligence provider
        (api.surplusintelligence.ai) with glm-5.3-flash — the provider is
        registered by the bundled frogix.pi.extensions entry, which also
        discovers its live catalog, and its key arrives through
        frogix.pi.envFile
      '';
    };

    skills = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ frontendDesignSkill ];
      description = ''
        shared skill directories passed to pi via --skill on every
        invocation (paths into this repo, e.g. ./skills/nixpkgs). defaults to
        anthropics/skills' frontend-design skill, which pushes pi toward
        deliberate, non-templated visual design when building web UI
      '';
    };

    webSearch = lib.mkOption {
      type = lib.types.attrs;
      default = {
        # "auto" (the package default) starts a session with only the compact
        # web_enable loader on models that accept tools added mid-conversation,
        # and exposes every web tool from the first request elsewhere. "eager"
        # always exposes them immediately: no web_enable turn and no chance the
        # model forgets to enable them, at the cost of sending the tool
        # definitions up front. cannot be combined with toolExposure
        # "deferred" (the package rejects that pair at startup).
        toolActivation = "eager";
      };
      description = ''
        contents merged into pi-web-access' own config,
        ~/.pi/agent/web-search.json (keys set here win; everything else —
        chosen provider, curator workflow, browser cookie settings — is
        preserved). defaults to toolActivation = "eager" so web_search,
        source_check, fetch_content and get_search_content are available from
        the first request instead of behind the web_enable loader
      '';
    };

    extensions = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
      default = [ ./pi/surplus-provider.ts ];
      description = ''
        shared extensions passed to pi via --extension on every invocation.
        the bundled default registers the surplus intelligence provider with
        live catalog discovery — refreshModels pulls /v1/models so new
        marketplace models and price changes need no repo edits; the
        fallback inside covers offline starts for glm-5.3-flash. pricing is
        key-scoped: the calling key's provider allow/deny list and trust
        preference (read via /v1/keys by secret prefix) filter the live
        /api/markets order book, so /model shows what this key can actually
        pay, and /models-by-price ranks models by blended 9:1 in:out $/1M
      '';
    };

    themes = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "shared themes passed to pi via --theme on every invocation";
    };

    promptTemplates = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "shared prompt templates passed to pi via --prompt-template on every invocation";
    };

    models = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        optional extra models.json installed into ~/.pi/agent/models.json
        (contents 0600; user-owned state wins once written — delete the file
        to re-seed). not needed for surplus: that provider and its live
        model/pricing discovery come from the bundled extension
        (frogix.pi.extensions), so catalogue entries never go stale here
      '';
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        environment variable -> sops secret name. the module declares each
        secret (owned by frogix.user: the pi wrapper runs as the invoking
        user, root-owned 0400 secrets would be unreadable) and exports it
        into pi's environment at launch — pi.nix cats the file at runtime,
        so nothing secret-shaped lands in the store. the keys must exist in
        the shared secrets.yaml; requires frogix.sops
      '';
      example = lib.literalExpression "{ OPENAI_API_KEY = \"openai_api_key\"; }";
    };

    env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        # 60s foreground probe for pi-bg-handoff (see bgHandoffConfig). set to
        # {} to fall back to the package's own 120s default.
        PI_BG_HANDOFF_CONFIG = "${bgHandoffConfig}";
      };
      description = ''
        extra literal environment variables exported before pi launches
        (merged with envFile/secrets). values land in the nix store, so only
        put non-secret settings here — secrets belong in the secrets knob or
        the envFile dotenv
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.envFile == null || cfg.secrets == { };
        message = "frogix.pi: envFile and secrets are exclusive — environment is either one sourced dotenv or an attrset of single variables";
      }
    ];

    programs.pi.coding-agent = {
      enable = true;
      rules = lib.mkDefault cfg.rules;
      settings = lib.mkDefault cfg.settings;
      skills = lib.mkDefault cfg.skills;
      extensions = lib.mkDefault cfg.extensions;
      themes = lib.mkDefault cfg.themes;
      promptTemplates = lib.mkDefault cfg.promptTemplates;
      models = lib.mkDefault cfg.models;
    };

    # both pi-bg-handoff and pi-subagents register a tool named bg_wait, and pi
    # refuses to load two extensions with the same tool name (fatal at startup).
    # pi-subagents documents renaming its wait tool for exactly this case; doing
    # that keeps every tool from both: bg_wait/bg_wait_for_task stay the
    # handoff ones (which the background-commands skill names), and subagents'
    # becomes subagent_wait — its prompts, status output and children follow
    # the configured name. the config lives in the agent dir, which the pi
    # wrapper only merges settings.json/mcp.json into, so it is contributed to
    # home-manager instead of written from system activation. sharedModules
    # scope it to the frogix user's home; without home-manager the file has to
    # be created by hand.
    home-manager.sharedModules = [
      (
        { config, lib, ... }:
        lib.mkIf (config.home.username == frogixUser) {
          home.file.".pi/agent/extensions/subagent/config.json".text = builtins.toJSON {
            waitTool.name = "subagent_wait";
          };

          # pi-web-access' config: merged rather than symlinked (see
          # webSearchConfig above), so the extension can keep writing it at
          # runtime. entryAfter writeBoundary so the agent dir can be created.
          # desktop entry: piPicker asks for the project directory first (a pi
          # session is pinned to the directory it starts in — see piPicker
          # above), then pi runs in a kitty of its own, with tmux's environment
          # stripped. pi's terminal-image detection short-circuits on TMUX*/
          # TERM_PROGRAM=tmux, and those variables leak into any process
          # launched from a tmux pane — including a `kitty -e pi` whose kitty
          # window actually talks to the compositor directly, no tmux in the
          # render path. launching through this entry keeps detection honest:
          # unset vars mean pi auto-detects kitty graphics when it owns the
          # terminal, and still falls back to text in a real tmux pane. needs
          # frogix.kitty: the entry exists for graphics, and it reuses the
          # module's kitty package rather than a bare `kitty` from PATH.
          xdg.desktopEntries = lib.mkIf config.frogix.kitty.enable {
            pi = {
              name = "pi";
              genericName = "Terminal Coding Agent";
              icon = "utilities-terminal";
              exec = lib.concatStringsSep " " [
                (lib.getExe config.programs.kitty.package)
                "--class pi"
                "-e"
                "env"
                "-u TMUX"
                "-u TMUX_PANE"
                "-u TERM_PROGRAM"
                "-u TERM_PROGRAM_VERSION"
                (lib.getExe piPicker)
              ];
              categories = [
                "Development"
                "TerminalEmulator"
              ];
              # hm's desktopEntries has no startupWMClass attr; the key goes
              # through the freeform settings set instead
              settings."StartupWMClass" = "pi";
            };
          };

          home.activation.piWebSearchConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            webSearchConfig="${config.home.homeDirectory}/.pi/agent/web-search.json"
            run mkdir -p "$(dirname "$webSearchConfig")"
            if [ -f "$webSearchConfig" ]; then
              mergedConfig="$(mktemp)"
              run ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$webSearchConfig" ${webSearchConfig} > "$mergedConfig"
              run mv "$mergedConfig" "$webSearchConfig"
            else
              run install -m 0600 ${webSearchConfig} "$webSearchConfig"
            fi
          '';
        }
      )
    ];

    # key material never enters the store: a dotenv secret (envFile) is
    # sourced wholesale, single-variable secrets are exported one by one, and
    # cfg.env adds plain values on top.
    programs.pi.coding-agent.environment =
      lib.mkIf (cfg.envFile != null || cfg.secrets != { } || cfg.env != { })
        (
          if cfg.envFile != null && cfg.env == { } then
            # unchanged fast path: hand pi.nix the dotenv itself
            config.sops.secrets.${cfg.envFile}.path
          else if cfg.envFile != null then
            # a dotenv AND extra values: pi.nix takes one file, not both, so source
            # the dotenv through a generated shim (pi.nix already wraps it in set -a)
            pkgs.writeText "pi-env.sh" ''
              . ${lib.escapeShellArg config.sops.secrets.${cfg.envFile}.path}
              ${lib.concatStringsSep "\n" (
                lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") cfg.env
              )}
            ''
          else
            (lib.mapAttrs (_envVar: secretName: {
              file = config.sops.secrets.${secretName}.path;
            }) cfg.secrets)
            // (lib.mapAttrs (_name: value: { inherit value; }) cfg.env)
        );

    # declare the mapped secrets so hosts only keep the plaintext in
    # secrets.yaml; mkDefault owner so an explicit host owner still wins
    # (pi's wrapper runs as the invoking user — root-owned 0400 secrets
    # would be unreadable)
    sops.secrets = lib.mkIf (config.frogix.sops.enable && (cfg.envFile != null || cfg.secrets != { })) (
      lib.genAttrs (lib.attrValues cfg.secrets ++ lib.optional (cfg.envFile != null) cfg.envFile)
        (_secretName: {
          owner = lib.mkDefault config.frogix.user;
        })
    );

    # both substituters from pi.nix's nixConfig: its own build results live on
    # pi.cachix.org, and the bun toolchain behind the -bun variant comes
    # through nix-community (bun2nix). extra-* on purpose: frogix.nix's
    # caches knob assigns substituters/trusted-public-keys outright, and the
    # extra variants append instead of clashing with it.
    nix.settings = lib.mkIf cfg.cache.enable {
      extra-substituters = [
        "https://pi.cachix.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}
