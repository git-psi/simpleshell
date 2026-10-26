#!/bin/sh
# Installs the simpleshell login screen for SDDM (run with sudo, or pkexec from the "Sync" button in
# Settings). Uses simpleshell's accent, wallpaper and cursor, and turns on every screen.
set -e
here=$(dirname "$(readlink -f "$0")")
dest=/usr/share/sddm/themes/simpleshell
user=${SUDO_USER:-$(getent passwd "${PKEXEC_UID:-$(id -u)}" | cut -d: -f1)}
home=$(getent passwd "$user" | cut -d: -f6)
settings=$home/.local/state/simpleshell/settings.json

rm -rf "$dest"
cp -r "$here/simpleshell" "$dest"
accent=$(grep -o '"accent": *"#[0-9a-fA-F]*"' "$settings" 2>/dev/null | grep -o '#[0-9a-fA-F]*' || true)
[ -n "$accent" ] && sed -i "s/^accent=.*/accent=$accent/" "$dest/theme.conf"
# Wallpaper blurred and darkened (readable text), copied into the theme: the sddm user can't read
# the home folder. Blurred small then scaled up (fast, same look).
wall=$(grep -o '"wallpaper": *"[^"]*"' "$settings" 2>/dev/null | sed 's/.*: *"\(.*\)"/\1/; s|^file://||' || true)
if [ -n "$wall" ] && [ -f "$wall" ]; then
    bg="$dest/background.jpg"
    if command -v magick >/dev/null; then
        magick "$wall" -resize '480x270^' -blur 0x4 -resize '1920x1080^' \
            -fill black -colorize 30% -quality 90 "$bg"
    else
        bg="$dest/background.${wall##*.}"
        cp "$wall" "$bg"
    fi
    chmod 644 "$bg"
    # Average color of the wallpaper: tint of the idle screen's clock.
    tint=$(magick "$wall" -resize 1x1\! -format '#%[hex:p{0,0}]' info: 2>/dev/null || true)
    [ -n "$tint" ] && sed -i "s/^tint=.*/tint=$tint/" "$dest/theme.conf"
    sed -i "s|^background=.*|background=$bg|" "$dest/theme.conf"
fi

# Cursor: the one from the Hyprland config (hl.env XCURSOR_THEME / XCURSOR_SIZE), also for SDDM and
# system-wide (session services, other users).
# The user's hyprland.lua wins over simpleshell.lua (which sets Bibata by default).
hypr="$home/.config/hypr/hyprland.lua $here/../hypr/simpleshell.lua"
cursor=$(cat $hypr 2>/dev/null | sed -n 's/.*XCURSOR_THEME", *"\([^"]*\)".*/\1/p' | head -1)
size=$(cat $hypr 2>/dev/null | sed -n 's/.*XCURSOR_SIZE", *"\([0-9]*\)".*/\1/p' | head -1)
size=${size:-24}
if [ -n "$cursor" ]; then
    mkdir -p /etc/environment.d
    printf 'XCURSOR_THEME=%s\nXCURSOR_SIZE=%s\n' "$cursor" "$size" > /etc/environment.d/90-simpleshell-cursor.conf
fi

# Screens: all on (xsetup.sh), whatever the current Monique profile.
install -m 755 "$here/xsetup.sh" "$dest/xsetup.sh"

# "zz-": read after the other files in /etc/sddm.conf.d, so it's the one picking the theme.
mkdir -p /etc/sddm.conf.d
{
    printf '[Theme]\nCurrent=simpleshell\n'
    [ -n "$cursor" ] && printf 'CursorTheme=%s\nCursorSize=%s\n' "$cursor" "$size"
    printf '\n[X11]\nDisplayCommand=%s\n' "$dest/xsetup.sh"
} > /etc/sddm.conf.d/zz-simpleshell.conf
echo "Login screen installed (accent ${accent:-default}, cursor ${cursor:-default}). It will show at the next login."
