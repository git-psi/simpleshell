// simpleshell — a minimal Hyprland shell: nothing on screen, everything within reach.
// Run with: qs -c simpleshell
import Quickshell
import QtQuick
import "panel"
import "osd"
import "power"
import "notifs"
import "launcher"
import "wallpaper"
import "polkit"
import "apps"
import "capture"

ShellRoot {
    Wallpaper {}
    QuickPanel {}
    StatusOsd {}
    WorkspaceOsd {}
    PowerMenu {}
    CaptureMenu {}
    CaptureOsd {}
    RegionPicker {}
    NotificationPanel {}
    NotificationToasts {}
    Launcher {}
    PolkitDialog {}
    Shortcuts {}
    Toggles {}
    Idle {}
    Battery {}
    Usb {}
    AppTheme {}
}
