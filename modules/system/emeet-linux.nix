{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.services.emeet-linux;

  src = pkgs.fetchFromGitHub {
    owner = "breno5g";
    repo = "emeet-linux";
    rev = "abfcc019a9f21de539d5881e97249a154e34386c";
    hash = "sha256-GgdlGVxI4pakSD/ZniMwfaqENQeFC409aIPHPAXUTZw=";
  };

  gstPlugins = with pkgs.gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-rs # gtk4paintablesink, the sink the live preview needs
  ];

  emeet = pkgs.python3Packages.buildPythonApplication {
    pname = "emeet-linux";
    version = "0.1.0";
    pyproject = true;
    inherit src;

    build-system = [ pkgs.python3Packages.setuptools ];
    dependencies = [ pkgs.python3Packages.pygobject3 ];

    nativeBuildInputs = [
      pkgs.wrapGAppsHook4
      pkgs.gobject-introspection
      pkgs.copyDesktopItems
    ];
    buildInputs = [
      pkgs.gtk4
      pkgs.libadwaita
    ]
    ++ gstPlugins;

    desktopItems = [ "${src}/data/io.github.breno5g.emeet.desktop" ];

    postInstall = ''
      install -Dm644 ${src}/data/io.github.breno5g.emeet.svg \
        $out/share/icons/hicolor/scalable/apps/io.github.breno5g.emeet.svg
      install -Dm644 ${src}/data/io.github.breno5g.emeet.metainfo.xml \
        $out/share/metainfo/io.github.breno5g.emeet.metainfo.xml
    '';

    # v4l2-ctl drives the controls, the GStreamer plugins decode and paint the preview
    makeWrapperArgs = [
      "--prefix"
      "GST_PLUGIN_SYSTEM_PATH_1_0"
      ":"
      (lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstPlugins)
      "--prefix"
      "PATH"
      ":"
      (lib.makeBinPath [ pkgs.v4l-utils ])
    ];

    nativeCheckInputs = [ pkgs.xvfb-run ];
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      export HOME=$(mktemp -d)
      export GSK_RENDERER=cairo
      xvfb-run -a python -m unittest discover -s tests
      runHook postCheck
    '';

    meta = {
      description = "Control panel with live preview for EMEET and other UVC webcams";
      homepage = "https://github.com/breno5g/emeet-linux";
      license = lib.licenses.mit;
      mainProgram = "emeet";
      platforms = lib.platforms.linux;
    };
  };

  # The camera keeps its controls in volatile RAM, so every replug hands back the
  # firmware defaults. This replays the app's own saved preset onto the fresh device.
  applyPresetPy = pkgs.writeText "emeet-apply-preset.py" ''
    import sys

    from emeet.presets import PresetStore
    from emeet.v4l2 import Camera


    def main():
        dev, preset_file, name = sys.argv[1:4]
        store = PresetStore(preset_file)
        if name not in store.names():
            print(f"emeet-apply-preset: no preset named {name!r} in {preset_file}", file=sys.stderr)
            return 0
        Camera(dev).apply(store.get(name))
        return 0


    sys.exit(main())
  '';

  applyPreset = pkgs.writeShellApplication {
    name = "emeet-apply-preset";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.v4l-utils
      pkgs.python3
    ];
    text = ''
      dev="$1"
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        v4l2-ctl -d "$dev" --list-ctrls >/dev/null 2>&1 && break
        sleep 0.5
      done
      export PYTHONPATH=${emeet}/${pkgs.python3.sitePackages}
      exec python3 ${applyPresetPy} "$@"
    '';
  };

  usbId = lib.splitString ":" cfg.applyPreset.usbId;
in
{
  options.services.emeet-linux = {
    applyPreset = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Re-apply a saved emeet-linux preset when the camera is plugged in.";
      };

      usbId = lib.mkOption {
        type = lib.types.strMatching "[0-9a-f]{4}:[0-9a-f]{4}";
        default = "328f:00e7";
        description = "Vendor:product id of the camera, as `lsusb` prints it.";
      };

      preset = lib.mkOption {
        type = lib.types.str;
        default = "default";
        description = ''
          Name of the preset to replay, as saved in the app's Presets tab.
          Single word: it ends up in a systemd ExecStart line.
        '';
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "theo";
        description = "User whose emeet-linux presets are read.";
      };

      presetFile = lib.mkOption {
        type = lib.types.str;
        default = "${config.users.users.${cfg.applyPreset.user}.home}/.config/emeet-linux/presets.json";
        defaultText = lib.literalExpression ''"''${config.users.users.''${cfg.applyPreset.user}.home}/.config/emeet-linux/presets.json"'';
        description = "JSON file the app writes its presets to.";
      };
    };
  };

  config = {
    environment.systemPackages = [ emeet ];

    services.udev.extraRules = lib.mkIf cfg.applyPreset.enable ''
      SUBSYSTEM=="video4linux", ATTR{index}=="0", ATTRS{idVendor}=="${builtins.elemAt usbId 0}", ATTRS{idProduct}=="${builtins.elemAt usbId 1}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="emeet-preset-apply@%k.service"
    '';

    systemd.services."emeet-preset-apply@" = lib.mkIf cfg.applyPreset.enable {
      description = "Apply the emeet-linux preset to /dev/%i";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${applyPreset}/bin/emeet-apply-preset /dev/%i ${cfg.applyPreset.presetFile} ${cfg.applyPreset.preset}";
      };
    };
  };
}