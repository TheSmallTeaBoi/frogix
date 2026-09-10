{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.hermes-agent = {
    enable = true;
    user = "theo";
    group = "users";
    createUser = false;

    environmentFiles = [ config.sops.secrets.hermes_env.path ];
    addToSystemPackages = true;
    extraPackages = with pkgs; [
      uv
      google-chrome
    ];
    workingDirectory = "/var/lib/hermes/workspace";

    extraPlugins = [
      (pkgs.callPackage ../../packages/hermes-profile-delegation.nix { })
    ];

    backend = {
      mode = "dashboard";
      host = "100.66.242.111";
      waitFor = "interface";
      interfaceName = "tailscale0";
      sessionTokenFile = config.sops.secrets.hermes_dashboard_token.path;
    };

    settings = {
      model = {
        provider = "opencode-go";
        model = "muse-spark-1.3-contributor";
      };

      agent.api_max_retries = 3;

      providers = {
        orcarouter = {
          api = "https://api.orcarouter.ai/v1";
          transport = "chat_completions";
          default_model = "z-ai/glm-5.3-flash-free";
          key_env = "ORCAROUTER_API_KEY";
        };
        opencode-zen-local = {
          api = "http://127.0.0.1:8787/v1";
          transport = "chat_completions";
          default_model = "mimo-v2.5-free";
        };
      };

      fallback_providers = [
        {
          model = "mimo-v2.5-free";
          provider = "opencode-zen-local";
        }
        {
          model = "meituan/longcat-2.0:free";
          provider = "nous";
        }
      ];

      model_aliases = {
        flash = {
          model = "deepseek-ai/deepseek-v4-flash-0731";
          provider = "nvidia";
        };
        nemotron = {
          model = "nvidia/nemotron-3.5-lightning-30b-a3b";
          provider = "nvidia";
        };
        pro = {
          model = "deepseek-v4-pro";
          provider = "opencode-go";
        };
        spark = {
          model = "muse-spark-1.3-contributor";
          provider = "opencode-go";
          api_mode = "codex_responses";
        };
        freespark = {
          model = "muse-spark-1.3-contributor-free";
          provider = "opencode-free";
        };
      };

      auxiliary = {
        vision = {
          model = "muse-spark-1.3-contributor";
          provider = "nvidia";
        };
        compression = {
          model = "muse-spark-1.3-contributor";
          provider = "opencode-go";
        };
        title_generation = {
          model = "auto";
          provider = "auto";
        };
        approval = {
          model = "auto";
          provider = "auto";
        };
        skills_hub = {
          model = "auto";
          provider = "auto";
        };
        mcp = {
          model = "auto";
          provider = "auto";
        };
        triage_specifier = {
          model = "auto";
          provider = "auto";
        };
        kanban_decomposer = {
          model = "auto";
          provider = "auto";
        };
        profile_describer = {
          model = "auto";
          provider = "auto";
        };
        goal_judge = {
          model = "auto";
          provider = "auto";
        };
        curator = {
          model = "auto";
          provider = "auto";
        };
        memory_query_rewrite = {
          model = "auto";
          provider = "auto";
        };
      };

      delegation = {
        model = "stepfun/step-3.7-flash:free";
        provider = "nous";
      };

      moa = {
        default_preset = "default";
        active_preset = "default";
        presets.default = {
          enabled = true;
          reference_models = [
            {
              provider = "nous";
              model = "meituan/longcat-2.0:free";
            }
            {
              provider = "nous";
              model = "upstage/solar-pro4:free";
            }
            {
              provider = "nous";
              model = "poolside/laguna-s-2.1:free";
            }
            {
              provider = "nous";
              model = "stepfun/step-3.7-flash:free";
            }
          ];
          aggregator = {
            provider = "opencode-go";
            model = "muse-spark-1.3-contributor";
          };
        };
      };

      memory.provider = "";

      # profile-delegation plugin: run delegated subagents under another
      # profile's identity. augment mode puts `profile`/`profile_memory`
      # straight onto the built-in delegate_task (needs the override below).
      plugins = {
        enabled = [ "profile-delegation" ];
        entries.profile-delegation = {
          allow_tool_override = true;
          mode = "augment";
        };
      };

      streaming.enabled = true;

      # let unpinned cron jobs follow the current global model instead of
      # drift-skipping when the global default changes
      # I'm cheap okay?
      cron.model_drift_guard = false;

      discord = {
        voice_fx.enabled = true;
        allow_any_attachment = true;
        free_response_channels = "";
      };

      gateway.discord.reactions = false;

      display.platforms.discord.streaming = false;

      stt.language = "es";

      browser.cdp_url = "http://127.0.0.1:9222";
    };
  };

  systemd.services.hermes-agent.serviceConfig.ReadWritePaths = [
    "/home/theo"
    "/storage"
    "/run/user/1000/bus"
  ];

  # The hermes cron doesn't work otherwise…
  # I wonder why this isn't default…
  # They probably vibe coded the flake.
  systemd.services.hermes-agent = {
    environment.XDG_RUNTIME_DIR = "/run/user/1000";
    environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    serviceConfig.NoNewPrivileges = lib.mkForce false;
  };

  # Headless chrome for hermes browser
  systemd.services.chrome-debug = {
    description = "Headless Chrome with remote debugging for Hermes";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "theo";
      ExecStart = "${pkgs.google-chrome}/bin/google-chrome-stable --headless=new --no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-port=9222 --user-data-dir=/var/lib/hermes/.hermes/chrome-debug --no-first-run --no-default-browser-check";
      Restart = "always";
      RestartSec = 5;
    };
  };

  system.activationScripts.hermes-cron-bin-true = lib.stringAfter [ "users" ] ''
    ln -sf ${pkgs.coreutils}/bin/true /bin/true 2>/dev/null || true
  '';
}
