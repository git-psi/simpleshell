#!/bin/sh
# simpleshell's colors applied to apps. Started by apps/AppTheme.qml on every theme or accent change,
# with the colors of Theme.qml. matugen (apps/matugen) writes the color files: GTK 3/4, Qt, KDE,
# Alacritty, micro, imv, mpv, rmpc, hyprlock, Hyprland borders.
# This script sets the rest (gsettings, icons, cursor, qt5ct/qt6ct, kdeglobals, micro, mpv, Alacritty).
# Usage: theme.sh light|dark accent accentInk bg sunken surface surfaceHi text textDim danger
set -e
mode=$1 accent=$2
here=$(dirname "$(readlink -f "$0")")
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
state=${XDG_STATE_HOME:-$HOME/.local/state}/simpleshell
mkdir -p "$state"

json=$(printf '{"hs":{"accent":"%s","ink":"%s","bg":"%s","sunken":"%s","surface":"%s","hi":"%s","text":"%s","dim":"%s","danger":"%s"}}' \
    "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}")
# "fidelity": the accent stays the picked color instead of being recomputed.
matugen color hex "$accent" -c "$here/matugen/config.toml" -m "$mode" -t scheme-fidelity -q \
    --import-json-string "$json"

# GTK apps: dark or light theme, and folders in the accent color.
if [ "$mode" = light ]; then scheme=prefer-light gtk=adw-gtk3; else scheme=prefer-dark gtk=adw-gtk3-dark; fi
gsettings set org.gnome.desktop.interface color-scheme "$scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk"
python3 "$here/folder-icons.py" "$accent"
gsettings set org.gnome.desktop.interface icon-theme simpleshell

# Cursor (hl.env XCURSOR_THEME of the Hyprland config): GTK apps, and the "default" theme for apps
# reading neither (XWayland…).
if [ -n "$XCURSOR_THEME" ]; then
    gsettings set org.gnome.desktop.interface cursor-theme "$XCURSOR_THEME"
    gsettings set org.gnome.desktop.interface cursor-size "${XCURSOR_SIZE:-24}"
    mkdir -p "$HOME/.local/share/icons/default"
    printf '[Icon Theme]\nInherits=%s\n' "$XCURSOR_THEME" > "$HOME/.local/share/icons/default/index.theme"
fi

# Qt apps (qt5ct / qt6ct, QT_QPA_PLATFORMTHEME in the Hyprland config): matugen's palette, Fusion
# style, same icons and fonts as GTK. Other settings are left to the user.
# Font tail in the QFont::toString format of Qt 5 (weight 50) or Qt 6 (weight 400).
font_tail() { if [ "$1" = 5 ]; then echo "-1,5,50,0,0,0,0,0"; else echo "-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; fi; }
for v in 5 6; do python3 -c '
import configparser, sys
p, colors, font, mono = sys.argv[1:]
c = configparser.RawConfigParser()
c.optionxform = str
c.read(p)
for s in ("Appearance", "Fonts"):
    c.has_section(s) or c.add_section(s)
a = c["Appearance"]
a.update(custom_palette="true", color_scheme_path=colors, icon_theme="simpleshell")
a.setdefault("style", "Fusion")
f = c["Fonts"]
f.setdefault("general", font)
f.setdefault("fixed", mono)
with open(p, "w") as out:
    c.write(out, space_around_delimiters=False)
' "$cfg/qt${v}ct/qt${v}ct.conf" "$cfg/qt${v}ct/colors/simpleshell.conf" \
    "\"Adwaita Sans,11,$(font_tail $v)\"" "\"Adwaita Mono,11,$(font_tail $v)\""
done

# KDE apps (Dolphin…): they also read their colors from kdeglobals; matugen's are merged in without
# touching the rest of the file.
python3 -c '
import configparser, sys
src, dst = sys.argv[1:]
c = configparser.RawConfigParser()
c.optionxform = str
c.read([dst, src])
with open(dst, "w") as out:
    c.write(out, space_around_delimiters=False)
' "$state/kdeglobals" "$cfg/kdeglobals"

# Window borders: right away (the file is also read by hypr/simpleshell.lua).
hyprctl eval "$(grep -v '^--' "$state/hypr-colors.lua")" >/dev/null 2>&1 || true

# micro: "simpleshell" colorscheme, set in its settings if it isn't already.
settings="$cfg/micro/settings.json"
mkdir -p "$cfg/micro"
[ -f "$settings" ] || echo '{}' > "$settings"
grep -q '"colorscheme": *"simpleshell"' "$settings" || python3 -c '
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["colorscheme"] = "simpleshell"
json.dump(d, open(p, "w"), indent=4)
' "$settings"

# mpv: mpv.conf (the user's) includes simpleshell.conf (OSD colors); created once if missing.
conf="$cfg/mpv/mpv.conf"
if [ ! -f "$conf" ]; then
    cat > "$conf" <<'EOF'
include="~~/simpleshell.conf"

# Hardware decoding when it's safe, high-quality scaling.
hwdec=auto-safe
profile=high-quality
# Remember the position when quitting, keep the window open at the end of a video.
save-position-on-quit=yes
keep-open=yes
# Screenshots (s key) in ~/Pictures/Screenshots.
screenshot-dir="~/Pictures/Screenshots"
screenshot-format=png
EOF
elif ! grep -q 'simpleshell.conf' "$conf"; then
    sed -i '1i include="~~/simpleshell.conf"' "$conf"
fi

# Alacritty config: created once if missing (after that, it belongs to the user).
[ -f "$cfg/alacritty/alacritty.toml" ] || cat > "$cfg/alacritty/alacritty.toml" <<'EOF'
[general]
import = ["~/.config/alacritty/simpleshell.toml"]

[window]
padding = { x = 12, y = 12 }
dynamic_padding = true

[font]
normal = { family = "JetBrainsMono Nerd Font" }
size = 11
EOF
# fish (with fastfetch on start, see install.sh) in the terminal, without changing the login shell.
if command -v fish >/dev/null && ! grep -q '^\[terminal' "$cfg/alacritty/alacritty.toml"; then
    printf '\n[terminal]\nshell = { program = "fish" }\n' >> "$cfg/alacritty/alacritty.toml"
fi
