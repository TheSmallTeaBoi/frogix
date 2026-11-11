{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Bind-mount existing ROM collection into RomM's library path.
  # /storage/Roms uses TOSEC naming; config.yml maps folders to slugs.
  fileSystems."/var/lib/romm/library/roms" = {
    device = "/storage/Roms";
    fsType = "none";
    options = [ "bind" ];
  };

  # Bind-mount curated console BIOS/firmware into RomM's firmware path.
  # /storage/Bios holds firmware organized by platform slug (bios/{slug}/),
  # sourced from the thor's EmuDeck bios stash. RomM's default firmware
  # template (bios/{platform}) scans it alongside ROMs on rescan.
  fileSystems."/var/lib/romm/library/bios" = {
    device = "/storage/Bios";
    fsType = "none";
    options = [ "bind" ];
  };

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
            f: prev.python3.withPackages (ps: f ps ++ [ ps.httpx2 ps.apprise ]);
        };
      };
    })
  ];

  services.romm = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 8080;
    nginx.virtualHost = "romm.localhost";
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

  services.nginx.virtualHosts."romm.localhost" = {
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
  systemd.services.romm-worker = {
    after = [ "storage.mount" ];
    requires = [ "storage.mount" ];
    serviceConfig.ExecStart = lib.mkForce "${config.services.romm.package}/bin/romm-worker high default low scans streaming";
  };
  systemd.services.romm-scheduler = {
    after = [ "storage.mount" ];
    requires = [ "storage.mount" ];
  };

  # Deploy config.yml (TOSEC folder -> RomM slug mappings) on rebuild.
  system.activationScripts.romm-config = ''
    mkdir -p /var/lib/romm/config
    cp ${./romm-config.yml} /var/lib/romm/config/config.yml
    chown romm:romm /var/lib/romm/config/config.yml
    chmod 644 /var/lib/romm/config/config.yml
  '';
}
