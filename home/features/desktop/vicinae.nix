# Vicinae launcher theme matching waybar/swaync styling
let
  colors = import ./colors.nix;
in
{
  xdg.dataFile."vicinae/themes/desktop.toml".text = ''
    [meta]
    name = "Desktop"
    description = "Matches waybar and swaync dark blue-lavender theme"
    variant = "dark"
    inherits = "vicinae-dark"

    [colors.core]
    accent = "${colors.focus}"
    accent_foreground = "${colors.backgroundDark}"
    background = "#1a1b2ed9"
    foreground = "${colors.focus}"
    secondary_background = "${colors.backgroundDark}"
    border = "${colors.focus}"

    [colors.main_window]
    border = "${colors.focus}"
    footer = { background = "colors.core.secondary_background" }

    [colors.settings_window]
    border = "${colors.focus}"

    [colors.accents]
    blue = "${colors.focus}"
    green = "#3a9c61"
    magenta = "${colors.tertiary}"
    orange = "#f0883e"
    red = "${colors.error}"
    yellow = "#bfae78"
    cyan = "#18a5b3"
    purple = "${colors.tertiary}"

    [colors.shortcut]
    border = "colors.core.border"

    [colors.text]
    default = "colors.core.foreground"
    muted = "${colors.onSurfaceVariant}"
    danger = "${colors.error}"
    success = "#3a9c61"
    placeholder = "${colors.outline}"
    selection = { background = "${colors.backgroundDark}", foreground = "${colors.focus}" }

    [colors.text.links]
    default = "${colors.focus}"
    visited = "${colors.tertiary}"

    [colors.input]
    border = "${colors.backgroundDark}"
    border_focus = "${colors.focus}"
    border_error = "${colors.error}"

    [colors.button.primary]
    background = "${colors.backgroundDark}"
    foreground = "${colors.focus}"
    hover = { background = "${colors.surfaceContainerHigh}" }
    focus = { outline = "colors.core.accent" }

    [colors.list.item.selection]
    background = "${colors.backgroundDark}"
    foreground = "${colors.focus}"
    secondary_background = "${colors.backgroundDark}"
    secondary_foreground = "${colors.focus}"

    [colors.grid.item]
    background = "${colors.backgroundDark}"
    hover = { outline = "${colors.focus}" }
    selection = { outline = "${colors.focus}" }

    [colors.scrollbars]
    background = "${colors.backgroundDark}"

    [colors.loading]
    bar = "${colors.focus}"
    spinner = "${colors.focus}"
  '';
}
