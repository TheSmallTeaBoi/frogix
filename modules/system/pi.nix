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
        # follow the rice: pywal.nix renders ~/.cache/wal/pi-theme.json and
        # symlinks ~/.pi/agent/themes/pywal.json at it, so the TUI recolors on
        # every set-wal. on a host with pywal disabled this theme is missing
        # and pi falls back to `system` (which samples the terminal palette
        # itself) after one startup warning — delete this line there.
        theme = "pywal";
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
          # pretty output: shiki-highlighted reads, colored bash, tree views
          "npm:@heyhuynhgiabuu/pi-pretty"
          # bg-handoff: moves long-running bash calls to background tasks, adds
          # host-side wait tools + the background-commands skill. its 60s probe
          # window comes from bgHandoffConfig below (frogix.pi.env)
          "npm:pi-bg-handoff"
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
      default = [ ];
      description = ''
        shared skill directories passed to pi via --skill on every
        invocation (paths into this repo, e.g. ./skills/nixpkgs)
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
        fallback inside covers offline starts for glm-5.3-flash
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
