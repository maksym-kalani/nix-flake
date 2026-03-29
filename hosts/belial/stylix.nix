{ pkgs, ... }:
{
  stylix = {
    enable = true;
    image = ../../home/features/desktop/assets/wallpaper.png;
    polarity = "dark";

    base16Scheme = {
      scheme = "Material Dark";
      author = "maksym";
      # Backgrounds
      base00 = "0f1019"; # background
      base01 = "1a1b2e"; # backgroundDark
      base02 = "292a2f"; # surfaceContainerHigh
      base03 = "45464f"; # surfaceVariant
      # Foregrounds
      base04 = "c6c5d0"; # onSurfaceVariant
      base05 = "e3e1e9"; # foreground
      base06 = "e3e1e9"; # foreground (same)
      base07 = "dde1ff"; # primaryFixed (lightest)
      # Accent colors
      base08 = "ffb4ab"; # error
      base09 = "e4bad9"; # tertiary (warm pink/mauve)
      base0A = "c3c5dd"; # secondary (muted blue-gray)
      base0B = "9ec49f"; # green (from original terminal palette)
      base0C = "9ec3c4"; # cyan (from original terminal palette)
      base0D = "b8c3ff"; # primary (blue-purple accent)
      base0E = "e4bad9"; # tertiary (pink, for italic/keyword roles)
      base0F = "93000a"; # errorContainer (dark red)
    };

    fonts = {
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.inter;
        name = "Inter";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sizes = {
        terminal = 12;
        applications = 11;
      };
    };

    opacity.popups = 0.7;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    targets.console.enable = false;
  };
}
