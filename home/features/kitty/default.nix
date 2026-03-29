{ lib, ... }:
{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    settings = {
      # Cursor
      cursor_blink_interval = "0.5";
      cursor_stop_blinking_after = 1;
      cursor_trail = 1;

      # Selection
      selection_foreground = "none";
      selection_background = "none";

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
      background_opacity = lib.mkForce "0.7";
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
