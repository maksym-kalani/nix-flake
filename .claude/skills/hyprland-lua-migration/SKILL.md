---
name: hyprland-lua-migration
description: Migrate a home-manager Hyprland config from hyprlang (settings = {...}) to Lua (configType = "lua"). Covers HM serializer rules, hl.* API surface, dispatcher mapping, Stylix conflict resolution, autostart, and validation steps.
---

# Hyprland hyprlang → Lua Migration

Invoke when: `wayland.windowManager.hyprland` exists in a `.nix` file and either (a) the user asks to migrate to Lua, or (b) a deprecation warning about `configType` is present.

## Step 0 — Pre-flight checks

```bash
# Confirm HM rev supports configType = "lua" (needs ≥ bd868f769, 2026-05-19)
nix flake metadata --json | jq '.locks.nodes["home-manager"].locked.rev'

# Find the Hyprland version for the stub path
nix eval .#nixosConfigurations.<host>.config.programs.hyprland.package.version
```

The authoritative API reference is the stub shipped with Hyprland:
```
/nix/store/<hash>-hyprland-<ver>/share/hypr/stubs/hl.meta.lua
```

**Validation target**: always use `nixosConfigurations.<host>`, not standalone `homeConfigurations`, because the standalone path may be missing Stylix NixOS modules.

## Step 1 — Enable Lua mode

```nix
wayland.windowManager.hyprland = {
  configType = "lua";   # add this line; silences the deprecation warning
  ...
};
```

## Step 2 — HM serializer rules

The HM Lua serializer converts `settings.<key>` → `hl.<key>(...)`. Rules:

| Nix form | Generated Lua |
|----------|--------------|
| `settings.foo = [ {...} {...} ]` | `hl.foo({...})` per entry |
| `{ _args = [ a b ]; }` | `hl.foo(a, b)` |
| `{ _args = [ a b opts ]; }` | `hl.foo(a, b, opts)` |
| `lib.generators.mkLuaInline "expr"` | `expr` emitted verbatim |
| `settings.config = { general = {...}; }` | `hl.config({ general = {...} })` |

**Valid top-level `hl.*` functions** (from `HL.API` in the stub):
`animation`, `bind`, `config`, `curve`, `device`, `env`, `exec_cmd`,
`gesture`, `layer_rule`, `monitor`, `on`, `permission`, `timer`,
`unbind`, `version`, `window_rule`, `workspace_rule`

**`hl.decoration`, `hl.general`, `hl.group`, `hl.misc` do NOT exist.** All subsections go inside `settings.config = { decoration = {...}; general = {...}; ... }`.

## Step 3 — Stylix conflict

Stylix injects into `settings.decoration`, `settings.general`, `settings.group`, `settings.misc` — all invalid top-level calls. Fix:

**a) Disable Stylix's Hyprland target:**
```nix
# home/features/desktop/stylix.nix
stylix.targets.hyprland.enable = false;
```

**b) Re-add the colors manually inside `settings.config`:**
```nix
settings.config = {
  general = {
    "col.active_border"   = "rgb(${config.lib.stylix.colors.base0D})";
    "col.inactive_border" = "rgb(${config.lib.stylix.colors.base03})";
  };
  decoration.shadow.color = "rgba(${config.lib.stylix.colors.base00}99)";
  group = {
    "col.border_active"        = "rgb(${config.lib.stylix.colors.base0D})";
    "col.border_inactive"      = "rgb(${config.lib.stylix.colors.base03})";
    "col.border_locked_active" = "rgb(${config.lib.stylix.colors.base0C})";
    groupbar = {
      "col.active"   = "rgb(${config.lib.stylix.colors.base0D})";
      "col.inactive" = "rgb(${config.lib.stylix.colors.base03})";
      text_color     = "rgb(${config.lib.stylix.colors.base05})";
    };
  };
  misc.background_color = "rgb(${config.lib.stylix.colors.base00})";
};
```

## Step 4 — Nix helper pattern

```nix
let
  raw = lib.generators.mkLuaInline;

  dsp = {
    exec  = cmd: raw ''hl.dsp.exec_cmd("${cmd}")'';
    close = raw "hl.dsp.window.close()";
    float = raw ''hl.dsp.window.float({ action = "toggle" })'';
    fullscreen = n: raw "hl.dsp.window.fullscreen(${toString n})";
    layout     = msg: raw ''hl.dsp.layout("${msg}")'';
    focus      = dir: raw ''hl.dsp.focus({ direction = "${dir}" })'';
    swap       = dir: raw ''hl.dsp.window.swap({ direction = "${dir}" })'';
    focusWorkspace  = ws: raw ''hl.dsp.focus({ workspace = "${toString ws}" })'';
    moveToWorkspace = ws: raw ''hl.dsp.window.move({ workspace = "${toString ws}" })'';
    toggleSpecial = raw "hl.dsp.workspace.toggle_special()";
    drag   = raw "hl.dsp.window.drag()";
    resize = raw "hl.dsp.window.resize()";
    raw    = cmd: raw ''hl.dsp.exec_raw("${cmd}")'';
    group  = {
      toggle = raw "hl.dsp.group.toggle()";
      next   = raw "hl.dsp.group.next()";
      prev   = raw "hl.dsp.group.prev()";
    };
  };

  bind'     = keys: dsp: { _args = [ keys dsp ]; };
  bindOpts' = keys: dsp: opts: { _args = [ keys dsp opts ]; };
in
```

## Step 5 — Dispatcher mapping

All dispatcher arguments use **object form**, not positional strings:

| hyprlang | Lua |
|----------|-----|
| `exec, cmd` | `hl.dsp.exec_cmd("cmd")` |
| `killactive` | `hl.dsp.window.close()` |
| `fullscreen, 0` | `hl.dsp.window.fullscreen(0)` |
| `togglefloating` | `hl.dsp.window.float({ action = "toggle" })` |
| `movefocus, l` | `hl.dsp.focus({ direction = "left" })` |
| `swapwindow, l` | `hl.dsp.window.swap({ direction = "left" })` |
| `workspace, N` | `hl.dsp.focus({ workspace = "N" })` |
| `workspace, e+1` | `hl.dsp.focus({ workspace = "e+1" })` |
| `movetoworkspace, N` | `hl.dsp.window.move({ workspace = "N" })` |
| `layoutmsg, X` | `hl.dsp.layout("X")` |
| `togglegroup` | `hl.dsp.group.toggle()` |
| `changegroupactive, f` | `hl.dsp.group.next()` |
| `changegroupactive, b` | `hl.dsp.group.prev()` |
| `togglespecialworkspace` | `hl.dsp.workspace.toggle_special()` |
| `movewindow` (mouse) | `hl.dsp.window.drag()` |
| `resizewindow` (mouse) | `hl.dsp.window.resize()` |
| `workspaceopt, allfloat` | `hl.dsp.exec_raw("workspaceopt allfloat")` |
| `resizeactive, 100 0` | `hl.dsp.exec_raw("resizeactive 100 0")` |

**No `binde`/`bindm` attributes.** All binds use a single `bind` list. Repeating and mouse options use `bindOpts'`:
```nix
(bindOpts' "XF86AudioRaiseVolume" (dsp.exec "wpctl set-volume ...") { repeating = true; })
(bindOpts' "SUPER + mouse:272"    dsp.drag                          { mouse = true; })
```

## Step 6 — Bezier curves and animations

Curves and animations are **top-level settings**, not inside `config`:

```nix
settings.curve = [
  { _args = [ "md3_decel" { type = "bezier"; points = [ [0.05 0.7] [0.1 1] ]; } ]; }
  # ... more curves
];

settings.animation = [
  { leaf = "windows"; enabled = true; speed = 3; bezier = "md3_decel"; style = "popin 60%"; }
  # ...
];
```

Use native Nix lists `[ [x y] [x y] ]` for bezier points — the serializer produces `{ { x, y }, { x, y } }` correctly.

## Step 7 — Autostart (exec-once equivalent)

**Use `hl.on("hyprland.start", function() ... end)` in `extraConfig`.** This fires exactly once at startup, not on `hyprctl reload`.

Do NOT use top-level `hl.exec_cmd(...)` — that runs on every config reload and will spawn duplicate processes.

```nix
extraConfig = ''
  hl.on("hyprland.start", function()
    hl.exec_cmd("${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("swaybg -i ${config.stylix.image} -m fill")
    hl.exec_cmd("wl-paste --watch cliphist store")
  end)
'';
```

When `systemd.enable = true`, HM already emits its own `hl.on("hyprland.start", ...)` for dbus/systemd activation. Multiple handlers for the same event are supported.

## Step 8 — Monitor transform

Hyprland transform values (clockwise rotation):
- `0` = normal
- `1` = 90° CW → physical top points **left**
- `2` = 180°
- `3` = 270° CW → physical top points **right**

## Step 9 — Env vars

```nix
let
  envEntry = pair:
    let parts = lib.splitString "," pair;
    in { _args = [ (builtins.head parts) (lib.concatStringsSep "," (builtins.tail parts)) ]; };
in
settings.env = map envEntry [
  "XDG_CURRENT_DESKTOP,Hyprland"
  "QT_QPA_PLATFORM,wayland;xcb"   # value may contain commas — tail-join handles it
  # ...
];
```

## Step 10 — Validation

```bash
# V1: must pass before anything else
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath

# V2: inspect generated Lua
nix build .#nixosConfigurations.<host>.config.home-manager.users.<user>.home.activationPackage
# find the hm_hyprhyprland.lua drv output, then:
#   grep "^hl\." — should NOT show hl.decoration / hl.general / hl.group / hl.misc
#   grep "hl\.curve\|hl\.animation" — curves and animations at top level
#   tail -30 — check hl.on("hyprland.start") block is present

# V3: apply
sudo nixos-rebuild switch --flake .#<host>

# V4: smoke test — keybinds, monitors, window rules, autostart
# V5: check logs
tail -F ~/.local/share/hyprland/hyprland.log
```

## Runtime monitor control (Lua mode)

`hyprctl keyword` is **completely broken** in Lua config mode — it returns "keyword can't work with non-legacy parsers". Use `hyprctl eval` with Lua expressions instead:

```bash
# Enable monitor
hyprctl eval 'hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "-3840x0", scale = 1, disabled = false })'

# Disable monitor
hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
```

Important: if a catch-all `hl.monitor({ output = "", disabled = true })` is in the static config, you **must** pass `disabled = false` explicitly in the enable eval — omitting it leaves the monitor disabled even when mode/position are set correctly.

Detection: use `hyprctl -j monitors` (not `monitors all`). When a monitor is active it appears with `disabled: false`; when disabled via eval it disappears from the list entirely.

## Common pitfalls

| Symptom | Cause | Fix |
|---------|-------|-----|
| `attempt to call a nil value (field 'decoration')` | Stylix injects `settings.decoration` | `targets.hyprland.enable = false` + manual colors |
| `hl.general({...})` / `hl.group({...})` crash | Same — Stylix injections | Same fix |
| `failed to parse key string: Unknown keysym "XF86Lock"` | Invalid keysym | Remove bind or use `code:NNN` |
| Two waybars after reload | `hl.exec_cmd` at top-level runs on every reload | Move into `hl.on("hyprland.start", ...)` |
| Autostart never ran | Config crashed before `-- extraConfig` section | Fix the crash first, then autostart works |
| Monitor not portrait | Wrong transform value | `transform = 1` for top-pointing-left, `transform = 3` for top-pointing-right |
