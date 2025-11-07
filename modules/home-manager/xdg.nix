{...}: {
  xdg.mimeApps.defaultApplications = {
    # Web
    "text/html" = ["firefox.desktop"];
    "x-scheme-handler/http" = ["firefox.desktop"];
    "x-scheme-handler/https" = ["firefox.desktop"];

    # Text and code
    "text/plain" = ["nvim.desktop"];

    # Images
    "image/png" = ["feh.desktop"];
    "image/jpeg" = ["feh.desktop"];
    "image/jpg" = ["feh.desktop"];
    "image/gif" = ["feh.desktop"];

    # Video / audio
    "video/mp4" = ["mpv.desktop"];
    "video/x-matroska" = ["mpv.desktop"];
    "audio/mpeg" = ["mpv.desktop"];
    "audio/flac" = ["mpv.desktop"];
    "audio/ogg" = ["mpv.desktop"];

    # Archives
    "application/zip" = ["xarchiver.desktop"];
    "application/x-7z-compressed" = ["xarchiver.desktop"];
    "application/x-rar" = ["xarchiver.desktop"];

    # PDF and docs
    "application/pdf" = ["firefox.desktop"];

    # Folders and file management
    "inode/directory" = ["nemo.desktop"];

    # Music
    "x-scheme-handler/music" = ["tauonmb.desktop"];
  };
}
