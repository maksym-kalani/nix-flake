{pkgs, ...}: {
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    settings = {
      # Cursor
      cursor = "#e3e1e9";
      cursor_text_color = "#c6c5d0";
      cursor_blink_interval = "0.5";
      cursor_stop_blinking_after = 1;
      cursor_trail = 1;

      # Colors
      foreground = "#e3e1e9";
      background = "#121318";
      selection_foreground = "none";
      selection_background = "none";
      url_color = "#b8c3ff";

      # Black
      color0 = "#4c4c4c";
      color8 = "#e3e1e9";

      # Red
      color1 = "#ffb4ab";
      color9 = "#c49ea0";

      # Green
      color2 = "#e3e1e9";
      color10 = "#9ec49f";

      # Yellow
      color3 = "#aca98a";
      color11 = "#c4c19e";

      # Blue
      color4 = "#b8c3ff";
      color12 = "#a39ec4";

      # Magenta
      color5 = "#ffb4ab";
      color13 = "#c49ec4";

      # Cyan
      color6 = "#e3e1e9";
      color14 = "#9ec3c4";

      # White
      color7 = "#f0f0f0";
      color15 = "#e7e7e7";

      # Font
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      # Window
      remember_window_size = "no";
      initial_window_width = 950;
      initial_window_height = 500;
      window_padding_width = 10;
      hide_window_decorations = "yes";
      background_opacity = "0.7";
      dynamic_background_opacity = "yes";
      confirm_os_window_close = 0;

      # Scrollback
      scrollback_lines = 2000;
      wheel_scroll_min_lines = 1;

      # Bell
      enable_audio_bell = "no";
    };
  };
}
