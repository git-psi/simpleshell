# Config Hyprland (exemple)

## Raccourcis de cette config

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
| `Super + Ctrl + ← / →` ou `Super + molette` | bureau précédent / suivant |
| `Super + Ctrl + Maj + ← / →` ou `Super + Maj + molette` | emmener la fenêtre sur le bureau précédent / suivant |
| `Super + Ctrl + 1…0` | aller au bureau n (`Maj` en plus : y emmener la fenêtre) |
| 3 doigts ← / → | changer de bureau |
| `Super + S`, ou 3–4 doigts ↑ / ↓ | afficher / cacher le scratchpad |
| `Super + Maj + S` | mettre la fenêtre dans le scratchpad, ou l'en sortir (pris par la capture de simpleshell, voir « Conflit ») |
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


-- Workspaces: Super + wheel or Super + Ctrl + left/right, on the active screen.
-- With Shift as well, the active window comes along.
-- Next: goes to the next existing workspace; at the end, opens a new one only if something is
-- left behind (Hyprland removes empty workspaces on its own when leaving them).
-- Previous: no wrap-around from the first to the last.
local function neighbour(step)
    local cur = hl.get_active_workspace()
    if not cur then return nil end
    for _, ws in ipairs(hl.get_workspaces()) do
        if not ws.special and ws.monitor and cur.monitor and ws.monitor.id == cur.monitor.id
            and (ws.id - cur.id) * step > 0 then
            return cur
        end
    end
    return nil, cur
end

-- go(target): focus to switch workspaces, window.move to take the window there.
-- keep: number of windows left behind when leaving.
local function workspace_next(go, keep)
    return function()
        local has_next, cur = neighbour(1)
        if has_next then
            hl.dispatch(go({ workspace = "m+1" }))
        elseif cur and keep(cur) > 0 then
            hl.dispatch(go({ workspace = "emptyn" }))
        end
    end
end

local function workspace_prev(go)
    return function()
        if neighbour(-1) then
            hl.dispatch(go({ workspace = "m-1" }))
        end
    end
end

local function stay(ws) return ws.windows end
local function leave(ws) return ws.windows - 1 end

local go_next, go_prev = workspace_next(hl.dsp.focus, stay), workspace_prev(hl.dsp.focus)
local take_next, take_prev = workspace_next(hl.dsp.window.move, leave), workspace_prev(hl.dsp.window.move)

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

-- Workspace by number: Super + Ctrl + 1…0 to go there, with Shift to take the window there.
-- AZERTY top row: bind the unshifted character (&, é, ", …).
local digits = { "ampersand", "eacute", "quotedbl", "apostrophe", "parenleft",
                 "minus", "egrave", "underscore", "ccedilla", "agrave" }
for i, key in ipairs(digits) do
    hl.bind(mod .. " + CTRL + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + CTRL + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
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
