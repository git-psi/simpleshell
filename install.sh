#!/usr/bin/env bash
# simpleshell installer for Arch Linux (and Arch-based distributions).
#
#   git clone https://github.com/git-psi/simpleshell ~/.config/quickshell/simpleshell
#   ~/.config/quickshell/simpleshell/install.sh
#
# Installs the shell and its dependencies (screenshots and screen recordings included), Alacritty
# (fish + fastfetch), Nautilus, imv, mpv, micro, Monique, the Bibata cursor (system-wide) and the
# SDDM login screen. Official repositories first;
# the AUR only for what isn't there (Monique, Bibata). Only the shell's own Hyprland config is
# installed (simpleshell.lua): your hyprland.lua stays yours (see the README for a full example).
# Safe to run again (updates links and packages, keeps existing files).
set -euo pipefail

repo=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
target=$cfg/quickshell/simpleshell
stamp=$(date +%Y%m%d-%H%M%S)

say()  { printf '\n\033[1;32m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
ask()  { local a; read -r -p "  $1 [y/N] " a; [[ $a == [yY]* ]]; }
# Moves an existing file or folder (not a link) aside before replacing it.
backup() { if [[ -e $1 && ! -L $1 ]]; then mv "$1" "$1.bak-$stamp"; warn "kept the old $1 as $1.bak-$stamp"; fi; }
link() { backup "$2"; mkdir -p "$(dirname "$2")"; ln -sfn "$1" "$2"; }

[[ $EUID -ne 0 ]] || { echo "Run it as your user, not root (sudo is asked when needed)."; exit 1; }
command -v pacman >/dev/null || { echo "This installer is for Arch Linux (pacman)."; exit 1; }

# --- Packages -----------------------------------------------------------------------------------
pkgs=(
    # Hyprland and the session
    hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit qt6-wayland
    hypridle hyprlock hyprsunset hyprpicker
    # Shell services: sound, network, Bluetooth, battery, power profiles, drives, brightness
    pipewire pipewire-pulse wireplumber networkmanager nm-connection-editor bluez bluez-utils
    upower power-profiles-daemon udisks2 gvfs brightnessctl ddcutil
    # Shell helpers: dialogs, notifications, links, theming, scripts
    zenity libnotify gtk3 xdg-utils matugen imagemagick python python-dbus python-gobject
    adw-gtk-theme qt5ct qt6ct
    # Screenshots and screen recordings (with sound), clipboard, video previews, Pictures/Videos folders
    grim wf-recorder wl-clipboard ffmpeg libpulse xdg-user-dirs
    # Fonts
    ttf-ubuntu-font-family ttf-opensans ttf-jetbrains-mono-nerd noto-fonts
    # Login screen
    sddm xorg-xrandr
    # Apps
    alacritty fish fastfetch nautilus imv mpv micro
)
# Quickshell, unless a fork providing it is already installed (e.g. noctalia-qs on CachyOS).
pacman -T quickshell >/dev/null || pkgs+=(quickshell)
aur=(monique bibata-cursor-theme-bin)

say "Installing packages (pacman)"
sudo pacman -S --needed "${pkgs[@]}"

say "Installing from the AUR: ${aur[*]}"
missing=()
for p in "${aur[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done
if (( ${#missing[@]} == 0 )); then
    echo "  already installed"
elif command -v paru >/dev/null; then
    paru -S --needed "${missing[@]}"
elif command -v yay >/dev/null; then
    yay -S --needed "${missing[@]}"
else
    # No AUR helper: build each package with makepkg.
    sudo pacman -S --needed base-devel git
    build=$(mktemp -d)
    for p in "${missing[@]}"; do
        git clone --depth 1 "https://aur.archlinux.org/$p.git" "$build/$p"
        (cd "$build/$p" && makepkg -si --needed)
    done
    rm -rf "$build"
fi

# --- The shell ----------------------------------------------------------------------------------
say "Installing the shell in $target"
if [[ $repo != "$(readlink -f "$target" 2>/dev/null)" ]]; then link "$repo" "$target"; fi
echo "  $target → $repo"

say "Hyprland config"
hypr=$cfg/hypr
mkdir -p "$hypr"
link "$target/hypr/simpleshell.lua" "$hypr/simpleshell.lua"
link "$target/hypr/hyprlock.conf" "$hypr/hyprlock.conf"
if [[ -f $hypr/hyprland.lua ]]; then
    if grep -q 'require("simpleshell")' "$hypr/hyprland.lua"; then
        echo "  hyprland.lua already loads simpleshell"
    else
        printf '\n-- simpleshell (launch, shortcuts, cursor, animations): keep it last.\nrequire("simpleshell")\n' >> "$hypr/hyprland.lua"
        echo "  added require(\"simpleshell\") at the end of hyprland.lua"
    fi
elif [[ -f $hypr/hyprland.conf ]]; then
    warn "you have a hyprland.conf: simpleshell needs a Lua config (hyprland.lua, Hyprland ≥ 0.56)."
    warn "Convert it, then add require(\"simpleshell\") at its end (example config in the README)."
else
    cat > "$hypr/hyprland.lua" <<'EOF'
-- Hyprland config. A complete example (keyboard, windows, workspaces, rules) is in the simpleshell
-- README: copy what you like above the line below.
-- Meanwhile: Super+Space opens the launcher (type "alacritty"), Super+A the quick panel.

-- simpleshell (launch, shortcuts, cursor, animations): keep it last.
require("simpleshell")
EOF
    echo "  created a minimal hyprland.lua"
fi

say "Terminal: fish with fastfetch"
mkdir -p "$cfg/fish/conf.d"
cp "$repo/dotfiles/fish/conf.d/simpleshell.fish" "$cfg/fish/conf.d/simpleshell.fish"
if [[ -f $cfg/fastfetch/config.jsonc ]] && ! cmp -s "$repo/dotfiles/fastfetch/config.jsonc" "$cfg/fastfetch/config.jsonc"; then
    backup "$cfg/fastfetch/config.jsonc"
fi
mkdir -p "$cfg/fastfetch"
cp "$repo/dotfiles/fastfetch/config.jsonc" "$cfg/fastfetch/config.jsonc"
echo "  Alacritty starts fish (its config is created by the shell on first start)"

say "Default apps"
xdg-mime default org.gnome.Nautilus.desktop inode/directory
for m in image/png image/jpeg image/gif image/webp image/bmp image/tiff image/svg+xml image/avif; do
    xdg-mime default imv.desktop "$m"
done
for m in video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo video/mpeg \
         audio/mpeg audio/flac audio/ogg audio/x-wav audio/mp4 audio/aac audio/opus; do
    xdg-mime default mpv.desktop "$m"
done
xdg-mime default micro.desktop text/plain
echo "  folders: Nautilus, images: imv, video and audio: mpv, text: micro"

# --- System -------------------------------------------------------------------------------------
say "System services"
sudo systemctl enable NetworkManager.service bluetooth.service
if systemctl is-enabled -q tlp.service 2>/dev/null; then
    warn "tlp is enabled: power-profiles-daemon (Power tile) left off"
else
    sudo systemctl enable power-profiles-daemon.service
fi
dm=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" 2>/dev/null || true)
if [[ -z $dm || $dm == display-manager.service ]]; then
    sudo systemctl enable sddm.service
elif [[ $dm != sddm.service ]]; then
    warn "the login manager is currently $dm"
    if ask "Replace it with SDDM (simpleshell's login screen)?"; then
        sudo systemctl enable -f sddm.service
    fi
fi

say "Login screen and system-wide cursor"
sudo "$target/sddm/install.sh"

say "Done"
cat <<EOF
  Log out (or restart), then pick Hyprland on the login screen.
  Already in Hyprland? Reload it (hyprctl reload) and start the shell: qs -c simpleshell -d

  Super+A        quick panel           Super+N        notifications
  Super+Space    launcher              Super+Escape   power menu
  Super+P        screens (Monique)     Print, Super+Shift+S   screenshot / recording

  simpleshell is the notification server and the polkit agent: don't also run mako, dunst,
  swaync, hyprpolkitagent or polkit-gnome.
EOF
