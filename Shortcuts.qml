// Shortcuts: Hyprland calls these names through hl.dsp.global("simpleshell:<name>").
// The same actions are available from the command line: qs -c simpleshell ipc call shell panel
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import "services"

Scope {
    GlobalShortcut {
        appid: "simpleshell"
        name: "panel"
        description: "Open or close the quick panel"
        onPressed: Ui.togglePanel()
    }
    GlobalShortcut {
        appid: "simpleshell"
        name: "notifications"
        description: "Open or close notifications"
        onPressed: Ui.toggleNotifs()
    }
    GlobalShortcut {
        appid: "simpleshell"
        name: "launcher"
        description: "App launcher"
        onPressed: Ui.toggleLauncher()
    }
    GlobalShortcut {
        appid: "simpleshell"
        name: "power"
        description: "Power menu"
        onPressed: Ui.togglePower()
    }

    // Print, Super+Shift+S: capture menu; with the menu open, the whole screen; while recording, stop.
    GlobalShortcut {
        appid: "simpleshell"
        name: "capture"
        description: "Capture menu, screenshot of the screen, or stop the recording"
        onPressed: Capture.key()
    }
    GlobalShortcut {
        appid: "simpleshell"
        name: "screenshotRegion"
        description: "Screenshot of a region"
        onPressed: Capture.screenshot("region")
    }

    GlobalShortcut {
        appid: "simpleshell"
        name: "swipeRight"
        description: "Swipe right: notifications, or close the quick panel"
        onPressed: Ui.swipe(true)
    }
    GlobalShortcut {
        appid: "simpleshell"
        name: "swipeLeft"
        description: "Swipe left: quick panel, or close notifications"
        onPressed: Ui.swipe(false)
    }

    IpcHandler {
        target: "shell"
        function panel(): void { Ui.togglePanel(); }
        function power(): void { Ui.togglePower(); }
        function notifications(): void { Ui.toggleNotifs(); }
        function launcher(): void { Ui.toggleLauncher(); }
        function dnd(): void { Ui.dnd = !Ui.dnd; }
        function clearNotifications(): void { Notifs.clear(); }
        function wifi(): void { page("wifi"); }
        function bluetooth(): void { page("bluetooth"); }
        function page(name: string): void { Ui.closeAll(); Ui.panelOpen = true; Ui.panelPage = name; }
        function capture(): void { Capture.key(); }
        // screen, region or window; record: screen or region.
        function screenshot(mode: string): void { Capture.screenshot(mode); }
        function record(mode: string): void { Capture.record(mode); }
        function stopRecording(): void { Capture.stop(); }
        function brightness(delta: int): void { Brightness.step(delta / 100); }
        function touchpad(on: bool): void { Ui.touchpad = on; }
        // Media keys: the playing player, otherwise the first one (playerctld is only a relay).
        function media(action: string): void {
            const players = Mpris.players.values.filter(p => !p.dbusName.endsWith(".playerctld"));
            const p = players.find(p => p.isPlaying) ?? players[0];
            if (!p) return;
            if (action === "toggle" && p.canTogglePlaying) p.togglePlaying();
            else if (action === "next" && p.canGoNext) p.next();
            else if (action === "previous" && p.canGoPrevious) p.previous();
            else if (action === "stop" && p.canControl) p.stop();
        }
    }
}
