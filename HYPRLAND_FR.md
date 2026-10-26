# Ma config Hyprland

[English version](HYPRLAND.md)

| Raccourci | Action |
|---|---|
| `Super + Entrée` ou `Super + T` | terminal (Alacritty) |
| `Super + E` | fichiers (Nautilus) |
| `Super + W` | navigateur (Firefox) |
| `Super + M` | musique (rmpc) |
| `Super + Q` | fermer la fenêtre |
| `Super + F` / `Super + Maj + F` | agrandir / plein écran |
| `Super + V` | fenêtre flottante ou non |
| `Super + flèches` | changer de fenêtre |
| `Super + Maj + flèches` | déplacer la fenêtre |
| `Super + Alt + flèches` | redimensionner la fenêtre |
| `Super + clic gauche / droit` | déplacer / redimensionner à la souris |
| `Super + Ctrl + ← / →` ou `Super + molette` | bureau précédent / suivant (5 par écran, en boucle) |
| `Super + Ctrl + Maj + ← / →` ou `Super + Maj + molette` | emmener la fenêtre sur le bureau précédent / suivant |
| `Super + 1…5` | aller au bureau n de l'écran (`Maj` en plus : y emmener la fenêtre) |
| 3 doigts ← / → | changer de bureau |
| `Super + S`, ou 3–4 doigts ↑ / ↓ | afficher / cacher le scratchpad |
| `Super + Maj + S` | mettre la fenêtre dans le scratchpad, ou l'en sortir (pris par la capture de SimpleShell) |
| `Super + Maj + P` | revenir au profil d'écran « Portable », puis ouvrir Monique |

## `hyprland.lua`

```lua
-- Minimal Hyprland config. The shell is simpleshell: its launch, keys, cursor, animations and
-- border colors live in simpleshell.lua (link to ~/.config/quickshell/simpleshell/hypr/simpleshell.lua).

-- Screens: managed by Monique (Super+P). Its moniqued service picks the profile from the connected
-- screens and the lid, and writes monitors.lua (missing until Monique has saved something).
pcall(require, "monitors")

-- Look: rounded corners like simpleshell, no shadow (shell rule). Border colors come from simpleshell
-- (accent).
hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 12,
        border_size = 3,
        layout      = "dwindle",
        snap        = { enabled = true, window_gap = 10, monitor_gap = 12 },
    },
    decoration = {
        rounding = 14,
        shadow   = { enabled = false },
        blur     = { enabled = false },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true, smart_split = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
    cursor = { inactive_timeout = 8 },
})

-- Keyboard and mouse
hl.config({
    input = {
        kb_layout          = "fr",
        numlock_by_default = true,
        follow_mouse       = 1,
        accel_profile      = "flat",
        touchpad = {
            natural_scroll       = false,
            disable_while_typing = false,
        },
    },
})

-- Apps don't maximize themselves (we decide, Super+F).
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Windows opening floating and centered: image viewer (imv) and screen settings (Monique, Super+P).
hl.window_rule({
    name   = "float-imv",
    match  = { class = "^imv$" },
    float  = true,
    center = true,
})
hl.window_rule({
    name   = "float-monique",
    match  = { class = "^com\\.github\\.monique$" },
    float  = true,
    center = true,
})

-- Small settings tools, floating and centered: sound (pavucontrol, EasyEffects), network,
-- appearance (nwg-look, qt5ct/qt6ct), CachyOS tools, HyprMod, GPG password, file search.
local floating_apps = {
    "org\\.pulseaudio\\.pavucontrol", "pavucontrol", "com\\.github\\.wwmm\\.easyeffects",
    "nm-connection-editor", "nwg-look", "nwg-displays", "qt5ct", "qt6ct",
    "btrfs-assistant", "org\\.cachyos\\..*", "cachyos-.*", "scx-manager",
    "io\\.github\\.bluemancz\\.hyprmod", "pinentry-.*", "org\\.gnupg\\.pinentry-qt",
    "catfish", "songrec", "nvidia-settings",
}
hl.window_rule({
    name   = "float-tools",
    match  = { class = "^(" .. table.concat(floating_apps, "|") .. ")$" },
    float  = true,
    center = true,
})

-- Qt tools would open almost fullscreen: fixed size.
hl.window_rule({
    name  = "size-qt-tools",
    match = { class = "^(qt5ct|qt6ct|btrfs-assistant|org\\.cachyos\\..*|scx-manager)$" },
    size  = "monitor_w*0.5 monitor_h*0.7",
})

-- "Open" / "Save as" windows (GTK portal) and modal dialogs.
hl.window_rule({
    name   = "float-file-chooser",
    match  = { class = "^xdg-desktop-portal-gtk$" },
    float  = true,
    center = true,
    size   = "monitor_w*0.6 monitor_h*0.65",
})
hl.window_rule({
    name   = "float-modal",
    match  = { modal = true },
    float  = true,
    center = true,
})

-- Firefox: picture-in-picture video (pinned on all workspaces, bottom right) and Library
-- (downloads, history). Titles in English and French.
hl.window_rule({
    name  = "firefox-pip",
    match = { class = "^firefox$", title = "^(Picture-in-Picture|Incrustation vidéo)$" },
    float = true,
    pin   = true,
    keep_aspect_ratio = true,
    size  = "monitor_w*0.3 monitor_h*0.3",
    move  = "monitor_w*0.68 monitor_h*0.66",
})
hl.window_rule({
    name   = "firefox-library",
    match  = { class = "^firefox$", title = "^(Bibliothèque|Library)$" },
    float  = true,
    center = true,
})

require("keybinds")
require("simpleshell")
```

## `keybinds.lua`

```lua
-- Shortcuts (AZERTY keyboard). simpleshell's (Super+A, N, Space, Escape, volume, brightness) are in
-- simpleshell.lua.
local mod = "SUPER"

-- Applications
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("alacritty"))
hl.bind(mod .. " + T",      hl.dsp.exec_cmd("alacritty"))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("nautilus --new-window"))
hl.bind(mod .. " + W",      hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + M",      hl.dsp.exec_cmd("rmpc-open"))  -- music (MPD)
-- Back to Monique's "Portable" profile (laptop screen only), then Monique to pick another.
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("monique --switch-profile Portable; monique"))

-- Windows
hl.bind(mod .. " + Q",         hl.dsp.window.close())
hl.bind(mod .. " + F",         hl.dsp.window.fullscreen({ mode = "maximized" }))   -- maximize
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))  -- fullscreen
hl.bind(mod .. " + V",         hl.dsp.window.float({ action = "toggle" }))         -- floating

-- Focus: Super + arrows; move: Super + Shift + arrows; resize: Super + Alt + arrows
local step = 40
local dirs = {
    left  = { x = -step, y = 0 },
    right = { x = step,  y = 0 },
    up    = { x = 0,     y = -step },
    down  = { x = 0,     y = step },
}
for dir, delta in pairs(dirs) do
    hl.bind(mod .. " + " .. dir,           hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. dir,   hl.dsp.window.move({ direction = dir }))
    hl.bind(mod .. " + ALT + " .. dir,     hl.dsp.window.resize({ x = delta.x, y = delta.y, relative = true }),
        { repeating = true })
end

-- With the mouse: Super + left click to move, Super + right click to resize.
-- A tiled window dropped on another goes to the side where the cursor is (smart_split); a floating
-- one snaps to the edges and other windows (snap).
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-- Workspaces: five per screen, always there (even empty), 1-5 on the first screen, 6-10 on the
-- second… Super + wheel or Super + Ctrl + left/right cycles through them: after the 5th comes the
-- 1st again. With Shift as well, the active window comes along.
-- Super + 1…5 goes to one of them, with Shift to take the window there.
local per_screen = 5

-- Screens in a stable order (the laptop's first): the n-th one gets workspaces (n-1)*5+1 … n*5.
local function screens()
    local list = hl.get_monitors()
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end
local function base(monitor)
    for i, m in ipairs(screens()) do
        if m.id == monitor.id then return (i - 1) * per_screen end
    end
    return 0
end

-- The rules keep each screen's workspaces on it, and alive when empty. Set again when screens
-- come and go (the previous ones are turned off).
local rules = {}
local function keep_workspaces()
    for _, rule in ipairs(rules) do rule:set_enabled(false) end
    rules = {}
    for i, m in ipairs(screens()) do
        for n = 1, per_screen do
            rules[#rules + 1] = hl.workspace_rule({
                workspace  = tostring((i - 1) * per_screen + n),
                monitor    = m.name,
                persistent = true,
                default    = n == 1,
            })
        end
    end
end
keep_workspaces()
hl.on("hyprland.start", keep_workspaces)
hl.on("monitor.added", keep_workspaces)
hl.on("monitor.removed", keep_workspaces)

-- n-th workspace (1…5) of the active screen, and the position of the one shown there.
local function workspace(n)
    local m = hl.get_active_monitor()
    return m and base(m) + n
end
local function position()
    local m = hl.get_active_monitor()
    local ws = m and hl.get_active_workspace(m)
    local p = ws and ws.id - base(m) or 1
    return (p >= 1 and p <= per_screen) and p or 1
end

-- go: focus to switch workspaces, window.move to take the window there.
local function cycle(go, step)
    return function()
        local target = workspace((position() - 1 + step) % per_screen + 1)
        if target then hl.dispatch(go({ workspace = target })) end
    end
end
local function to(go, n)
    return function()
        local target = workspace(n)
        if target then hl.dispatch(go({ workspace = target })) end
    end
end

local go_next, go_prev = cycle(hl.dsp.focus, 1), cycle(hl.dsp.focus, -1)
local take_next, take_prev = cycle(hl.dsp.window.move, 1), cycle(hl.dsp.window.move, -1)

hl.bind(mod .. " + mouse_down",           go_next)
hl.bind(mod .. " + mouse_up",             go_prev)
hl.bind(mod .. " + CTRL + right",         go_next,   { repeating = true })
hl.bind(mod .. " + CTRL + left",          go_prev,   { repeating = true })
hl.bind(mod .. " + SHIFT + mouse_down",   take_next)
hl.bind(mod .. " + SHIFT + mouse_up",     take_prev)
hl.bind(mod .. " + CTRL + SHIFT + right", take_next, { repeating = true })
hl.bind(mod .. " + CTRL + SHIFT + left",  take_prev, { repeating = true })

-- Touchpad: three fingers horizontally, the workspace follows the fingers.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Super + 1…5. AZERTY top row: bind the unshifted character (&, é, ", ', ().
local digits = { "ampersand", "eacute", "quotedbl", "apostrophe", "parenleft" }
for n, key in ipairs(digits) do
    hl.bind(mod .. " + " .. key,         to(hl.dsp.focus, n))
    hl.bind(mod .. " + SHIFT + " .. key, to(hl.dsp.window.move, n))
end

-- Scratchpad: a hidden workspace over the desktop, Super+S to show or hide it.
-- It always rises from the bottom of the screen. A terminal is started there at login; if it's
-- closed, Super+S shows the empty scratchpad and anything can be opened there.
-- Super+Shift+S: moves the active window into it, or out of it to the workspace below.
-- Margin around the scratchpad, the same on all four edges and on every screen; normal gap
-- between its windows.
local scratch_margin = 100   -- px
hl.workspace_rule({ workspace = "special:scratch", gaps_out = scratch_margin })
hl.on("hyprland.start", function()
    hl.exec_cmd("alacritty", { workspace = "special:scratch silent" })
end)
hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("scratch"))

-- Touchpad, three or four fingers: up opens the scratchpad, down closes it.
-- Hyprland's "special" gesture would follow the fingers, but opens and closes in the same
-- direction and doesn't follow the fingers when closing: not used.
local function scratch_shown()
    local ws = hl.get_active_special_workspace()
    return ws ~= nil and ws.name == "special:scratch"
end
local function scratch_swipe(fingers, direction, show)
    hl.gesture({ fingers = fingers, direction = direction, action = function()
        if scratch_shown() ~= show then hl.dispatch(hl.dsp.workspace.toggle_special("scratch")) end
    end })
end
for _, fingers in ipairs({ 3, 4 }) do
    scratch_swipe(fingers, "up", true)
    scratch_swipe(fingers, "down", false)
end
hl.bind(mod .. " + SHIFT + S", function()
    local win = hl.get_active_window()
    if not win then return end
    local mon = win.monitor
    if win.workspace and win.workspace.name == "special:scratch" and mon and mon.active_workspace then
        hl.dispatch(hl.dsp.window.move({ workspace = mon.active_workspace.id }))
        if mon.active_special_workspace then hl.dispatch(hl.dsp.workspace.toggle_special("scratch")) end
    else
        hl.dispatch(hl.dsp.window.move({ workspace = "special:scratch" }))
    end
end)
```
