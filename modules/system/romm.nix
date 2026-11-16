{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.frogix.romm;
in
{
  options.frogix.romm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "RomM game library + nginx vhost, with its postgres/redis backing services";
    };
    libraryDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "host ROM collection bind-mounted into the container path";
    };
    biosDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "host BIOS collection bind-mounted into the container path";
    };
    resourcesDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "host path for scraped media (covers, screenshots); keeps multi-GB scraper output off the root fs";
    };
    useTosec = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "deploy the bundled config.yml mapping TOSEC-named library folders to RomM platform slugs";
    };
    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "address the RomM API binds";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "port the RomM API listens on";
    };
    virtualHost = lib.mkOption {
      type = lib.types.str;
      default = "romm.localhost";
      description = "nginx vhost serving RomM";
    };
  };

  config = lib.mkIf cfg.enable {
    # Bind-mount existing ROM collection into RomM's library path.
    # /storage/Roms uses TOSEC naming; config.yml maps folders to slugs.
    fileSystems = lib.mkMerge [
      (lib.mkIf (cfg.libraryDir != null) {
        "/var/lib/romm/library/roms" = {
          device = cfg.libraryDir;
          fsType = "none";
          options = [ "bind" ];
        };

        # Bind-mount curated console BIOS/firmware into RomM's firmware path.
        # /storage/Bios holds firmware organized by platform slug (bios/{slug}/),
        # sourced from the thor's EmuDeck bios stash. RomM's default firmware
        # template (bios/{platform}) scans it alongside ROMs on rescan.
        "/var/lib/romm/library/bios" = {
          device = cfg.biosDir;
          fsType = "none";
          options = [ "bind" ];
        };
      })
      (lib.mkIf (cfg.resourcesDir != null) {
        # Bind-mount scraped media (covers, screenshots, fanart) onto the host
        # collection disk. RomM otherwise writes every scraped image to
        # /var/lib/romm/resources on the root fs; across a 507G library that is
        # tens of GB the root partition never asked for.
        "/var/lib/romm/resources" = {
          device = cfg.resourcesDir;
          fsType = "none";
          options = [ "bind" ];
        };
      })
    ];

    # RomM reports its version from backend/__version__.py; source builds leave
    # "<version>" there and /api/heartbeat then answers "development", which
    # version-gating clients (Tender, EmuDeck RomM Sync) refuse. nixpkgs stamps
    # the real version in postPatch itself since the 2026-11 pin, so the local
    # override that used to do it was removed 2026-11-06 (both substitutions
    # together made --replace-fail abort the build).

    # RomM 5.4.x switched its http client from httpx to httpx2 and imports it at
    # module load, but nixpkgs' romm package list still ships only httpx, so
    # romm-migrate dies with "ModuleNotFoundError: No module named 'httpx2'" and
    # the unit start-loops (Result: start-limit-hit). Upstream fix is
    # NixOS/nixpkgs#580640 (still unmerged), which also adds apprise. Inject both
    # into romm's python env here; drop this overlay once the pinned nixpkgs
    # carries the fix.
    nixpkgs.overlays = [
      (final: prev: {
        romm = prev.romm.override {
          python3 = prev.python3 // {
            withPackages =
              f:
              prev.python3.withPackages (
                ps:
                f ps
                ++ [
                  ps.httpx2
                  ps.apprise
                ]
              );
          };
        };
      })
    ];

    services.romm = {
      enable = true;
      listenAddress = cfg.listenAddress;
      port = cfg.port;
      nginx.virtualHost = cfg.virtualHost;
      environmentFile = config.sops.secrets.romm_env.path;
      extraEnvironment = {
        HASHEOUS_API_ENABLED = "true";
        LAUNCHBOX_API_ENABLED = "true";
        ENABLE_SCHEDULED_UPDATE_LAUNCHBOX_METADATA = "true";
        FLASHPOINT_API_ENABLED = "true";
        HLTB_API_ENABLED = "true";
        PLAYMATCH_API_ENABLED = "true";
      };
    };

    services.nginx.virtualHosts.${cfg.virtualHost} = {
      default = true;
    };

    users.users.romm.extraGroups = [ "users" ];

    systemd.services.romm = {
      after = [ "storage.mount" ];
      requires = [ "storage.mount" ];
    };
    systemd.services.romm-init = {
      after = [ "storage.mount" ];
      requires = [ "storage.mount" ];
    };
    # RomM 5.4 moved scans onto their own rq queue ("scans") and streaming
    # teardowns onto ("streaming"), but nixpkgs' romm-worker wrapper still launches
    # rq with a hardcoded "high default low". The API gates on a live listener for
    # the scans queue, so every scan is refused with "No scan worker is listening,
    # so the scan cannot be queued". Upstream runs a dedicated scan worker process;
    # the wrapper forwards extra args to rq, so appending the queues to the one
    # worker is the least-moving fix (a scan then occupies the worker for its
    # duration, same as 5.2.x did). Split it into a second unit if scans ever need
    # to run alongside metadata tasks.
    # The nixos module gives every satellite unit Requires=romm.service. When
    # romm.service's first start attempt fails and systemd's own retry then
    # succeeds, the satellites' start jobs are cancelled with result 'dependency'
    # -- which Restart=on-failure never rescues. They stay dead while the web UI
    # looks fine, and every scan is refused with "No scan worker is listening".
    # Happened 2026-11-13: the switch restarted postgres in the same transaction
    # and romm's ExecStartPre ran against it cold. The worker/scheduler/watcher
    # only need redis and the database, not the API server (upstream runs them as
    # independent processes), so order them after romm.service without requiring
    # it, and give romm itself room for a slow migrate.
    systemd.services.romm.serviceConfig.TimeoutStartSec = lib.mkForce "5m";
    systemd.services.romm-worker = {
      after = [ "storage.mount" ];
      requires = lib.mkForce [ "storage.mount" ];
      wants = [ "romm.service" ];
      serviceConfig.ExecStart = lib.mkForce "${config.services.romm.package}/bin/romm-worker high default low scans streaming";
    };
    systemd.services.romm-scheduler = {
      after = [ "storage.mount" ];
      requires = lib.mkForce [ "storage.mount" ];
      wants = [ "romm.service" ];
    };
    systemd.services.romm-watcher = {
      after = [ "storage.mount" ];
      requires = lib.mkForce [ "storage.mount" ];
      wants = [ "romm.service" ];
    };

    # Deploy config.yml (TOSEC folder -> RomM slug mappings) on rebuild.
    system.activationScripts.romm-config = lib.mkIf cfg.useTosec ''
      mkdir -p /var/lib/romm/config
      cp ${./romm-config.yml} /var/lib/romm/config/config.yml
      chown romm:romm /var/lib/romm/config/config.yml
      chmod 644 /var/lib/romm/config/config.yml
    '';
  };
}
