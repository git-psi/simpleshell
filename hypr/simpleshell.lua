-- simpleshell — Hyprland integration (Hyprland ≥ 0.56 with hyprland.lua): launch, shortcuts,
-- animations. Install: link it into ~/.config/hypr, then require it AFTER your own keybinds:
--   ln -s ~/.config/quickshell/simpleshell/hypr/simpleshell.lua ~/.config/hypr/simpleshell.lua
--   require("simpleshell")   -- at the end of hyprland.lua

-- Session: cursor (Bibata, installed system-wide by install.sh), Qt apps themed by the shell
-- (qt5ct / qt6ct; the qt5ct key works for Qt 5 and Qt 6), the same variables for apps started by
-- D-Bus / systemd (portals, services), then the shell. Monique's service (screen profiles) waits
-- for graphical-session.target, never reached without uwsm: start it ourselves.
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd QT_QPA_PLATFORMTHEME XCURSOR_THEME"
        .. " XCURSOR_SIZE WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP"
        .. "; systemctl --user start moniqued")
    hl.exec_cmd("qs -c simpleshell -n -d")
end)

-- Safety net: if no screen is on anymore (external screen unplugged while the profile turns the
-- laptop's off, booting without the external screen…), turn the laptop's screen back on.
-- FALLBACK = placeholder screen Hyprland creates when there's none left. Left without a screen,
-- the shell keeps its windows on the placeholder and shows nothing: restart it too.
-- Several events can fire together (monitor removed + config reloaded when Monique applies a
-- profile): only one restart at a time, otherwise each one starts its own shell and two
-- instances then toggle their panels on every shortcut (Super+A opening then closing at once).
local restarting = false
local function ensure_screen()
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= "FALLBACK" then return end
    end
    hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
    if restarting then return end
    restarting = true
    hl.exec_cmd("sleep 1; pkill -x qs; pkill -x quickshell; sleep 0.5; qs -c simpleshell -n -d")
    hl.timer(function() restarting = false end, { timeout = 5000, type = "oneshot" })
end
local function ensure_screen_soon()
    hl.timer(ensure_screen, { timeout = 500, type = "oneshot" })   -- ms, time for Hyprland to settle its screens
end
hl.on("monitor.removed", ensure_screen_soon)
hl.on("hyprland.start", ensure_screen_soon)
hl.on("config.reloaded", ensure_screen_soon)

-- If hyprlock crashes (black screen), it can be restarted from a TTY:
--   hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock")'
hl.config({ misc = { allow_session_lock_restore = true } })

-- These keys may already be taken by another shell: free them first.
local function rebind(key, dispatcher, opts)
    hl.unbind(key)
    hl.bind(key, dispatcher, opts)
end

-- Quick panel, notifications, launcher and power menu
rebind("SUPER + A",      hl.dsp.global("simpleshell:panel"))
rebind("SUPER + N",      hl.dsp.global("simpleshell:notifications"))
rebind("SUPER + Space",  hl.dsp.global("simpleshell:launcher"))
rebind("SUPER + Escape", hl.dsp.global("simpleshell:power"))
-- Power button: the power menu too, instead of shutting down right away. logind leaves the key to
-- Hyprland while this session runs (inhibitor held until Hyprland quits).
rebind("XF86PowerOff",   hl.dsp.global("simpleshell:power"))
hl.on("hyprland.start", function()
    hl.exec_cmd("systemd-inhibit --what=handle-power-key --who=simpleshell"
        .. " --why='Power button opens the power menu' --mode=block sleep infinity")
end)

-- Touchpad, four fingers: swipe right for notifications (left of the screen), swipe left for the
-- quick panel (on the right). The other way closes whatever is open (simpleshell).
local function swipe(direction, name)
    hl.gesture({ fingers = 4, direction = direction,
                 action = function() hl.dispatch(hl.dsp.global("simpleshell:" .. name)) end })
end
swipe("right", "swipeRight")
swipe("left",  "swipeLeft")

-- Screenshots and recordings: Print or Super+Shift+S opens the capture menu; pressed again with the
-- menu open, the whole screen; while recording, stops it. Shift+Print: a region right away.
rebind("Print",               hl.dsp.global("simpleshell:capture"))
rebind("SUPER + SHIFT + S",   hl.dsp.global("simpleshell:capture"))
rebind("SHIFT + Print",       hl.dsp.global("simpleshell:screenshotRegion"))

-- Volume keys (the volume OSD shows on its own)
local held = { locked = true, repeating = true }
rebind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), held)
rebind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), held)
rebind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
rebind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Brightness keys (all screens, external ones included)
rebind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("qs -c simpleshell ipc call shell brightness 5"), held)
rebind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs -c simpleshell ipc call shell brightness -5"), held)

-- Media keys (keyboard, Bluetooth headset): current MPRIS player, through simpleshell.
local function media(action)
    return hl.dsp.exec_cmd("qs -c simpleshell ipc call shell media " .. action)
end
rebind("XF86AudioPlay",  media("toggle"), { locked = true })
rebind("XF86AudioPause", media("toggle"), { locked = true })
rebind("XF86AudioNext",  media("next"),     { locked = true })
rebind("XF86AudioPrev",  media("previous"), { locked = true })
rebind("XF86AudioStop",  media("stop"),     { locked = true })

-- Keyboard backlight. On ASUS laptops the kernel (asus-wmi) often handles these keys itself and
-- sends nothing: these shortcuts only serve other keyboards. The OSD follows the value.
local kbd = "brightnessctl -q -d '*::kbd_backlight' set "
rebind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd(kbd .. "+1"), held)
rebind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(kbd .. "1-"), held)

-- Touchpad: dedicated key. Hyprland turns it off, simpleshell shows the OSD. Hyprland names
-- devices after the kernel's, lowercase with dashes ("ELAN1203:00 04F3:307A Touchpad" →
-- "elan1203:00-04f3:307a-touchpad"): the first touchpad of /proc/bus/input/devices.
local function touchpad_name()
    local f = io.open("/proc/bus/input/devices")
    if not f then return nil end
    for line in f:lines() do
        local name = line:match('^N: Name="(.*[Tt]ouchpad.*)"$')
        if name then f:close(); return name:lower():gsub(" ", "-") end
    end
    f:close()
end
local touchpad = { name = touchpad_name(), enabled = true }
rebind("XF86TouchpadToggle", function()
    if not touchpad.name then return end
    touchpad.enabled = not touchpad.enabled
    hl.device(touchpad)
    hl.exec_cmd("qs -c simpleshell ipc call shell touchpad " .. tostring(touchpad.enabled))
end)

-- Display key (projector, F9): screen settings in Monique. On the ASUS it sends Super+P like on
-- Windows; XF86Display for other keyboards.
rebind("SUPER + P",   hl.dsp.exec_cmd("monique"))
rebind("XF86Display", hl.dsp.exec_cmd("monique"))
-- Fan (Fn+F5), airplane mode and sleep: handled by the kernel / logind, the OSD follows.

-- zenity windows opened from Settings (accent color, wallpaper): floating and centered, at their
-- natural size, instead of taking a tile.
hl.window_rule({
    name   = "float-zenity",
    match  = { class = "^zenity$" },
    float  = true,
    center = true,
})

-- The shell animates its own windows: no Hyprland fade on top.
hl.layer_rule({ match = { namespace = "simpleshell-.*" }, no_anim = 1 })

-- Window animations, at the shell's pace (Theme.qml), Emil Kowalski's curves: everything starts
-- fast and settles softly, without bounce. out to appear or disappear, drawer (iOS-like) for
-- sliding workspaces, move for windows moving into place. Speed in tenths of a second.
hl.curve("out",    { type = "bezier", points = { {0.23, 1},   {0.32, 1} } })
hl.curve("drawer", { type = "bezier", points = { {0.32, 0.72}, {0, 1} } })
hl.curve("move",   { type = "bezier", points = { {0.77, 0},   {0.175, 1} } })
hl.animation({ leaf = "global",           enabled = true,  speed = 2,   bezier = "out" })
hl.animation({ leaf = "windowsIn",        enabled = true,  speed = 2,   bezier = "out", style = "popin 95%" })
hl.animation({ leaf = "windowsOut",       enabled = true,  speed = 1.4, bezier = "out", style = "popin 95%" })
hl.animation({ leaf = "windowsMove",      enabled = true,  speed = 2.5, bezier = "move" })
hl.animation({ leaf = "fadeIn",           enabled = true,  speed = 2,   bezier = "out" })
hl.animation({ leaf = "fadeOut",          enabled = true,  speed = 1.4, bezier = "out" })
hl.animation({ leaf = "layersIn",         enabled = true,  speed = 2,   bezier = "out", style = "fade" })
hl.animation({ leaf = "layersOut",        enabled = true,  speed = 1.4, bezier = "out", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true,  speed = 2,   bezier = "out" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true,  speed = 1.4, bezier = "out" })
hl.animation({ leaf = "borderangle",      enabled = false })
hl.animation({ leaf = "workspaces",       enabled = true,  speed = 3,   bezier = "drawer", style = "slide" })
-- Scratchpad (keybinds.lua): rises from the bottom of the screen.
hl.animation({ leaf = "specialWorkspace", enabled = true,  speed = 3,   bezier = "drawer", style = "slidevert" })

-- Window border colors, written by simpleshell (apps/theme.sh) from the accent.
pcall(dofile, os.getenv("HOME") .. "/.local/state/simpleshell/hypr-colors.lua")
