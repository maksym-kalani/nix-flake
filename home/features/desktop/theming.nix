{ pkgs, ... }:
let
  colors = import ./colors.nix;

  # GTK CSS color definitions to override Adwaita colors
  gtkColorsCss = ''
    /*
     * GTK Colors
     * Material Design 3 palette
     */

    @define-color accent_color ${colors.primary};
    @define-color accent_fg_color ${colors.onPrimaryFixed};
    @define-color accent_bg_color ${colors.primary};
    @define-color window_bg_color ${colors.background};
    @define-color window_fg_color ${colors.foreground};
    @define-color headerbar_bg_color ${colors.background};
    @define-color headerbar_fg_color ${colors.foreground};
    @define-color popover_bg_color ${colors.background};
    @define-color popover_fg_color ${colors.foreground};
    @define-color view_bg_color ${colors.background};
    @define-color view_fg_color ${colors.foreground};
    @define-color card_bg_color ${colors.background};
    @define-color card_fg_color ${colors.foreground};
    @define-color sidebar_bg_color @window_bg_color;
    @define-color sidebar_fg_color @window_fg_color;
    @define-color sidebar_border_color @window_bg_color;
    @define-color sidebar_backdrop_color @window_bg_color;
  '';
in
{
  gtk = {
    enable = true;

    theme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    iconTheme = {
      name = "Colloid";
      package = pkgs.colloid-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    font = {
      name = "Inter";
      size = 11;
    };

    gtk3.extraConfig = {
      gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
      gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
      gtk-button-images = 0;
      gtk-menu-images = 0;
      gtk-enable-event-sounds = 1;
      gtk-enable-input-feedback-sounds = 0;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-application-prefer-dark-theme = 1;
    };

    gtk3.extraCss = gtkColorsCss;

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraCss = gtkColorsCss;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  # Kvantum configuration - use Nordic-Darker-Solid theme
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=Nordic-Darker-Solid
  '';

  # Qt5ct configuration
  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    color_scheme_path=
    custom_palette=false
    style=kvantum

    [Fonts]
    fixed="Monospace,10,-1,5,50,0,0,0,0,0"
    general="Inter,10,-1,5,50,0,0,0,0,0"

    [Interface]
    activate_item_on_single_click=1
    buttonbox_layout=0
    cursor_flash_time=1000
    dialog_buttons_have_icons=1
    double_click_interval=400
    gui_effects=@Invalid()
    menus_have_icons=true
    stylesheets=@Invalid()
  '';

  # Qt6ct darker color scheme (matching CachyOS)
  xdg.configFile."qt6ct/colors/darker.conf".text = ''
    [ColorScheme]
    active_colors=#ffffffff, #ff424245, #ff979797, #ff5e5c5b, #ff302f2e, #ff4a4947, #ffffffff, #ffffffff, #ffffffff, #ff3d3d3d, #ff222020, #ffe7e4e0, #ff12608a, #fff9f9f9, #ff0986d3, #ffa70b06, #ff5c5b5a, #ffffffff, #ff3f3f36, #ffffffff, #80ffffff
    disabled_colors=#ff808080, #ff424245, #ff979797, #ff5e5c5b, #ff302f2e, #ff4a4947, #ff808080, #ffffffff, #ff808080, #ff3d3d3d, #ff222020, #ffe7e4e0, #ff12608a, #ff808080, #ff0986d3, #ffa70b06, #ff5c5b5a, #ffffffff, #ff3f3f36, #ffffffff, #80ffffff
    inactive_colors=#ffffffff, #ff424245, #ff979797, #ff5e5c5b, #ff302f2e, #ff4a4947, #ffffffff, #ffffffff, #ffffffff, #ff3d3d3d, #ff222020, #ffe7e4e0, #ff12608a, #fff9f9f9, #ff0986d3, #ffa70b06, #ff5c5b5a, #ffffffff, #ff3f3f36, #ffffffff, #80ffffff
  '';

  # Qt6ct configuration - use Breeze with darker palette (matching CachyOS)
  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=~/.config/qt6ct/colors/darker.conf
    custom_palette=true
    icon_theme=breeze-dark
    standard_dialogs=default
    style=Breeze

    [Interface]
    activate_item_on_single_click=1
    buttonbox_layout=0
    cursor_flash_time=1000
    dialog_buttons_have_icons=1
    double_click_interval=400
    gui_effects=@Invalid()
    keyboard_scheme=2
    menus_have_icons=true
    show_shortcuts_in_context_menus=true
    stylesheets=@Invalid()
    toolbutton_style=4
    underline_shortcut=1
    wheel_scroll_lines=3

    [Troubleshooting]
    force_raster_widgets=1
    ignored_applications=@Invalid()
  '';

  # Fonts for waybar, rofi, etc.
  fonts.fontconfig = {
    enable = true;
    defaultFonts = { };
  };

  xdg.configFile."fontconfig/conf.d/10-antialiasing.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <match target="font">
        <edit name="antialias" mode="assign"><bool>true</bool></edit>
        <edit name="hinting" mode="assign"><bool>true</bool></edit>
        <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
        <edit name="rgba" mode="assign"><const>rgb</const></edit>
        <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
      </match>
    </fontconfig>
  '';
}
