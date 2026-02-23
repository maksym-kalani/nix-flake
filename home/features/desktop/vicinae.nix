let
  colors = import ./colors.nix;
in
{
  xdg.dataFile."vicinae/themes/desktop.toml".text = ''
    [meta]
    name = "Desktop"
    description = "Material Design 3 dark theme"
    variant = "dark"
    inherits = "vicinae-dark"

    [colors.core]
    accent = "${colors.primary}"
    accent_foreground = "${colors.onPrimary}"
    background = "#D9${builtins.substring 1 6 colors.backgroundDark}"
    foreground = "${colors.onSurface}"
    secondary_background = "colors.core.background"
    border = "${colors.outlineVariant}"

    [colors.main_window]
    border = "${colors.outlineVariant}"

    [colors.accents]
    blue = "${colors.primary}"
    green = "#3a9c61"
    magenta = "${colors.tertiary}"
    orange = "#f0883e"
    red = "${colors.error}"
    yellow = "#bfae78"
    cyan = "#18a5b3"
    purple = "${colors.tertiary}"

    [colors.text]
    muted = "${colors.onSurfaceVariant}"
    danger = "${colors.error}"
    success = "#3a9c61"
    placeholder = "${colors.outline}"
    selection = { background = "${colors.primaryContainer}", foreground = "${colors.onPrimaryContainer}" }

    [colors.text.links]
    default = "${colors.primary}"
    visited = "${colors.tertiary}"

    [colors.input]
    border = "${colors.surfaceVariant}"
    border_focus = "${colors.primary}"
    border_error = "${colors.error}"

    [colors.button.primary]
    background = "${colors.surfaceContainerHigh}"
    foreground = "${colors.onSurface}"
    hover = { background = "${colors.surfaceContainerHighest}" }

    [colors.list.item.selection]
    background = "${colors.primaryContainer}"
    foreground = "${colors.onPrimaryContainer}"
    secondary_background = "${colors.surfaceContainerHigh}"
    secondary_foreground = "${colors.onSurfaceVariant}"

    [colors.grid.item]
    background = "${colors.surfaceContainer}"
    hover = { outline = "${colors.primary}" }
    selection = { outline = "${colors.primary}" }

    [colors.scrollbars]
    background = "${colors.surfaceContainerHigh}"

    [colors.loading]
    bar = "${colors.primary}"
    spinner = "${colors.primary}"
  '';
}
