# XDG MIME type associations (file type defaults)
{ ... }:
{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Web browser - Zen
      "x-scheme-handler/http" = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
      "x-scheme-handler/chrome" = "zen.desktop";
      "text/html" = "zen.desktop";
      "application/x-extension-htm" = "zen.desktop";
      "application/x-extension-html" = "zen.desktop";
      "application/x-extension-shtml" = "zen.desktop";
      "application/xhtml+xml" = "zen.desktop";
      "application/x-extension-xhtml" = "zen.desktop";
      "application/x-extension-xht" = "zen.desktop";

      # PDF - Papers
      "application/pdf" = "org.gnome.Papers.desktop";

      # Images - Loupe
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/gif" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";
      "image/bmp" = "org.gnome.Loupe.desktop";

      # Video - VLC
      "video/mp4" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "video/x-msvideo" = "vlc.desktop";
      "video/quicktime" = "vlc.desktop";
      "video/x-flv" = "vlc.desktop";

      # Audio - VLC
      "audio/mpeg" = "vlc.desktop";
      "audio/mp3" = "vlc.desktop";
      "audio/flac" = "vlc.desktop";
      "audio/x-flac" = "vlc.desktop";
      "audio/wav" = "vlc.desktop";
      "audio/x-wav" = "vlc.desktop";
      "audio/ogg" = "vlc.desktop";
      "audio/opus" = "vlc.desktop";
      "audio/x-ms-wma" = "vlc.desktop";
      "audio/mp4" = "vlc.desktop";

      # Code/text - Zed
      "text/plain" = "dev.zed.Zed.desktop";
      "text/x-csrc" = "dev.zed.Zed.desktop";
      "text/x-c++src" = "dev.zed.Zed.desktop";
      "text/x-python" = "dev.zed.Zed.desktop";
      "text/x-java" = "dev.zed.Zed.desktop";
      "text/x-shellscript" = "dev.zed.Zed.desktop";
      "text/x-script.python" = "dev.zed.Zed.desktop";
      "text/x-makefile" = "dev.zed.Zed.desktop";
      "text/x-markdown" = "dev.zed.Zed.desktop";
      "text/markdown" = "dev.zed.Zed.desktop";
      "application/json" = "dev.zed.Zed.desktop";
      "application/x-yaml" = "dev.zed.Zed.desktop";
      "application/toml" = "dev.zed.Zed.desktop";
      "application/xml" = "dev.zed.Zed.desktop";

      # JetBrains
      "x-scheme-handler/jetbrains" = "jetbrains-toolbox.desktop";

      # Discord - Vesktop
      "x-scheme-handler/discord" = "vesktop.desktop";

      # File manager
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
  };
}
