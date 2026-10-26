pragma Singleton
// Settings edited by hand (those of the Settings page live in Settings.qml).
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    // Keyboard backlight (/sys/class/leds/*kbd_backlight*, the first one), followed by the OSD.
    // Empty without one.
    property string kbdLed: ""
    Process {
        running: true
        command: ["sh", "-c", "ls -d /sys/class/leds/*kbd_backlight* 2>/dev/null | head -n 1"]
        stdout: StdioCollector { onStreamFinished: kbdLed = text.trim().replace(/^.*\//, "") }
    }
    // Launcher web search (space + text), picked in Settings: the text is appended.
    readonly property var searchEngines: [
        { key: "google", name: "Google", url: "https://www.google.com/search?q=" },
        { key: "duckduckgo", name: "DuckDuckGo", url: "https://duckduckgo.com/?q=" },
        { key: "startpage", name: "Startpage", url: "https://www.startpage.com/do/search?q=" }
    ]
    readonly property string searchUrl: (searchEngines.find(e => e.key === Settings.searchEngine) ?? searchEngines[0]).url
    // Files opened from Settings > Configuration: the shell's own (the rest of the Hyprland config
    // belongs to the user).
    readonly property var configFiles: [
        { title: "Shortcuts and animations", path: Quickshell.shellDir + "/hypr/simpleshell.lua" },
        { title: "Lock screen", path: Quickshell.shellDir + "/hypr/hyprlock.conf" },
        { title: "Shell folder", path: Quickshell.shellDir }
    ]

    readonly property var commands: ({
        lock:     ["loginctl", "lock-session"],
        suspend:  [Quickshell.shellDir + "/power/greeter.sh"],   // SDDM greeter, session kept
        logout:   ["hyprctl", "dispatch", "hl.dsp.exit()"],   // Lua Hyprland config
        poweroff: ["systemctl", "poweroff"],
        reboot:   ["systemctl", "reboot"]
    })

    function run(name) {
        const cmd = commands[name];
        if (cmd) Quickshell.execDetached(cmd);
    }
}
