{ ... }:
{
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    # Web
    "text/html" = [ "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/http" = [ "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/https" = [ "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/ftp" = [ "org.qutebrowser.qutebrowser.desktop" ];
    "application/xhtml+xml" = [ "org.qutebrowser.qutebrowser.desktop" ];
    "application/xml" = [ "org.qutebrowser.qutebrowser.desktop" ];

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

    # PDF and docs
    "application/pdf" = [ "org.qutebrowser.qutebrowser.desktop" ];

    # Folders and file management
    "inode/directory" = [ "nemo.desktop" ];

    # Music
    "x-scheme-handler/music" = [ "mpv.desktop" ];
  };
}
