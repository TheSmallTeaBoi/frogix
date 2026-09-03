{ ... }:
{
  xdg.mimeApps.defaultApplications = {
    # Web
    "text/html" = [ "qute.desktop" ];
    "x-scheme-handler/http" = [ "qute.desktop" ];
    "x-scheme-handler/https" = [ "qute.desktop" ];
    "x-scheme-handler/ftp" = [ "qute.desktop" ];
    "application/xhtml+xml" = [ "qute.desktop" ];
    "application/xml" = [ "qute.desktop" ];

    # Text and code
    "text/plain" = [ "emacs.desktop" ];
    "text/markdown" = [ "emacs.desktop" ];
    "text/x-markdown" = [ "emacs.desktop" ];
    "text/x-org" = [ "emacs.desktop" ];
    "text/css" = [ "emacs.desktop" ];
    "text/javascript" = [ "emacs.desktop" ];
    "text/x-python" = [ "emacs.desktop" ];
    "text/x-shellscript" = [ "emacs.desktop" ];
    "text/x-csrc" = [ "emacs.desktop" ];
    "text/xml" = [ "emacs.desktop" ];
    "application/json" = [ "emacs.desktop" ];
    "application/x-nix" = [ "emacs.desktop" ];

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
    "application/pdf" = [ "qute.desktop" ];

    # Folders and file management
    "inode/directory" = [ "nemo.desktop" ];

    # Music
    "x-scheme-handler/music" = [ "mpv.desktop" ];
  };
}
