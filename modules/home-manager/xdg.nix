{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.xdg;
in
{
  options.frogix."xdg".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "mime default applications";
  };

  config = lib.mkIf cfg.enable {
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      # Images
      "image/png" = [ "feh.desktop" ];
      "image/jpeg" = [ "feh.desktop" ];
      "image/jpg" = [ "feh.desktop" ];
      "image/gif" = [ "feh.desktop" ];

      # Video / audio
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];
      "audio/ogg" = [ "mpv.desktop" ];

      # Archives
      "application/zip" = [ "xarchiver.desktop" ];
      "application/x-7z-compressed" = [ "xarchiver.desktop" ];
      "application/x-rar" = [ "xarchiver.desktop" ];

      # Folders and file management
      "inode/directory" = [ "nemo.desktop" ];

      # Music
      "x-scheme-handler/music" = [ "mpv.desktop" ];
    }
    # the browser and the editor are frogix areas that can be switched off;
    # leave those defaults unset then so a host (or another app) can claim them.
    // lib.optionalAttrs config.frogix.qutebrowser.enable {
      # Web
      "text/html" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/http" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/https" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/ftp" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "application/xhtml+xml" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "application/xml" = [ "org.qutebrowser.qutebrowser.desktop" ];

      # PDF and docs
      "application/pdf" = [ "org.qutebrowser.qutebrowser.desktop" ];
    }
    // lib.optionalAttrs config.frogix.emacs.enable {
      # Text and code
      "text/plain" = [ "emacsclient.desktop" ];
      "text/markdown" = [ "emacsclient.desktop" ];
      "text/x-markdown" = [ "emacsclient.desktop" ];
      "text/x-org" = [ "emacsclient.desktop" ];
      "text/css" = [ "emacsclient.desktop" ];
      "text/javascript" = [ "emacsclient.desktop" ];
      "text/x-python" = [ "emacsclient.desktop" ];
      "text/x-shellscript" = [ "emacsclient.desktop" ];
      "text/x-csrc" = [ "emacsclient.desktop" ];
      "text/xml" = [ "emacsclient.desktop" ];
      "application/json" = [ "emacsclient.desktop" ];
      "application/x-nix" = [ "emacsclient.desktop" ];
    };
  };
}
