_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    programs.mpv = {
      enable = true;
      config.ytdl-format = "bestvideo+bestaudio/best";
      scripts = [pkgs.mpvScripts.mpris];
    };
    stylix.targets.mpv.enable = true;

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "audio/flac" = ["mpv.desktop"];
        "audio/mpeg" = ["mpv.desktop"];
        "audio/ogg" = ["mpv.desktop"];
        "image/gif" = ["mpv.desktop"];
        "image/jpeg" = ["mpv.desktop"];
        "image/png" = ["mpv.desktop"];
        "image/webp" = ["mpv.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "video/webm" = ["mpv.desktop"];
        "video/x-matroska" = ["mpv.desktop"];
      };
    };
  };
}
