{pkgs, ...}: {
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
      name = "Cantarell";
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

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  # Qt5ct configuration
  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    color_scheme_path=
    custom_palette=false
    style=kvantum

    [Fonts]
    fixed="Monospace,10,-1,5,50,0,0,0,0,0"
    general="Noto Sans,10,-1,5,50,0,0,0,0,0"

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

  # Qt6ct configuration
  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=
    custom_palette=false
    icon_theme=Colloid
    standard_dialogs=default
    style=kvantum

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

  home.packages = with pkgs; [
    qt5ct
    qt6ct
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum
  ];
}
