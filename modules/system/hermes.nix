{ config, pkgs, ... }:
{
  services.hermes-agent = {
    enable = true;
    user = "theo";
    group = "users";
    createUser = false;
    settings.model.default = "muse-spark-1.3-contributor-free";
    settings.model.provider = "opencode-free";
    settings.gateway.discord.reactions = false;
    settings.model_aliases = {
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
    settings.fallback_providers = [
      {
        provider = "openai-codex";
        model = "gpt-5.4-mini";
      }
      {
        provider = "opencode-go";
        model = "muse-spark-1.3-contributor";
        api_mode = "codex_responses";
      }
      {
        provider = "nvidia";
        model = "nvidia/nemotron-3.5-lightning-30b-a3b";
      }
    ];
    settings.auxiliary.vision = {
      model = "meta/llama-3.2-11b-vision-instruct";
      provider = "nvidia";
    };
    environmentFiles = [ config.sops.secrets.hermes_env.path ];
    addToSystemPackages = true;
    extraPackages = with pkgs; [
      uv
      google-chrome
    ];
    workingDirectory = "/var/lib/hermes/workspace";
    settings.memory.provider = "";
    backend = {
      mode = "dashboard";
      host = "100.66.242.111";
      waitFor = "interface";
      interfaceName = "tailscale0";
      sessionTokenFile = config.sops.secrets.hermes_dashboard_token.path;
    };
  };

  systemd.services.hermes-agent.serviceConfig.ReadWritePaths = [
    "/home/theo"
    "/storage"
  ];
}
