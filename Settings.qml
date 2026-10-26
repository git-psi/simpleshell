pragma Singleton
// Settings picked on the Settings page, stored in ~/.local/state/simpleshell/settings.json.
// (Config.qml holds the settings edited by hand.)
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string dir: Quickshell.env("HOME") + "/.local/state/simpleshell"
    property bool ready: false

    property alias accent: data.accent
    property alias light: data.light
    property alias wallpaper: data.wallpaper
    property alias showTray: data.showTray
    property alias showMedia: data.showMedia
    property alias batteryPercent: data.batteryPercent
    property alias clockSeconds: data.clockSeconds
    property alias notifVertical: data.notifVertical       // "top" or "bottom"
    property alias notifHorizontal: data.notifHorizontal   // "left", "center" or "right"
    // Idle time in minutes (0 = never): lock, screens off, suspend.
    property alias lockMinutes: data.lockMinutes
    property alias screenOffMinutes: data.screenOffMinutes
    property alias suspendMinutes: data.suspendMinutes
    property alias nightTemperature: data.nightTemperature // night light, in kelvins
    property alias searchEngine: data.searchEngine         // key of Config.searchEngines
    property alias recordAudio: data.recordAudio           // screen recordings with sound
    // File read (or created): the values are no longer the defaults.
    property bool loaded: false

    // Accent outside the list: color picker (zenity), which answers "rgb(r,g,b)", or eyedropper
    // (hyprpicker), which answers "#rrggbb". Nothing (cancelled): the accent stays.
    function setAccentFrom(text) {
        const t = text.trim();
        if (/^#[0-9a-fA-F]{6}$/.test(t)) { root.accent = t.toLowerCase(); return; }
        const m = t.match(/(\d+)\D+(\d+)\D+(\d+)/);
        if (!m) return;
        root.accent = "#" + [m[1], m[2], m[3]].map(v => Number(v).toString(16).padStart(2, "0")).join("");
    }
    // While picking, the panel stays open (a click outside doesn't close it).
    readonly property bool picking: accentPicker.running || pipette.running
    function pickAccent() { accentPicker.running = true; }
    Process {
        id: accentPicker
        command: ["zenity", "--color-selection", "--title=Accent color", "--color=" + root.accent]
        stdout: StdioCollector { onStreamFinished: root.setAccentFrom(text) }
    }
    // --quiet would also silence the picked color.
    function pickAccentOnScreen() { pipette.running = true; }
    Process {
        id: pipette
        command: ["hyprpicker", "--format=hex", "--no-fancy", "--lowercase-hex"]
        stdout: StdioCollector { onStreamFinished: root.setAccentFrom(text) }
    }

    // Wallpaper picked in a file chooser (zenity).
    function pickWallpaper() { picker.running = true; }
    Process {
        id: picker
        command: ["zenity", "--file-selection", "--title=Wallpaper",
            "--filename=" + Quickshell.env("HOME") + "/",
            "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.bmp"]
        stdout: StdioCollector {
            onStreamFinished: { const f = text.trim(); if (f !== "") root.wallpaper = f; }
        }
    }

    // SDDM login screen: reinstalled with the current accent and wallpaper (pkexec, simpleshell is
    // the polkit agent). 126/127 = authentication cancelled or denied.
    property bool sddmFailed: false
    readonly property bool sddmSyncing: sddm.running
    function syncSddm() { sddmFailed = false; sddm.running = true; }
    Process {
        id: sddm
        command: ["pkexec", Quickshell.shellDir + "/sddm/install.sh"]
        onExited: (code) => root.sddmFailed = code !== 0 && code !== 126 && code !== 127
    }

    // The folder must exist before the first write.
    Process {
        running: true
        command: ["mkdir", "-p", root.dir]
        onExited: root.ready = true
    }

    FileView {
        path: root.ready ? root.dir + "/settings.json" : ""
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.loaded = true
        onLoadFailed: { writeAdapter(); root.loaded = true; }   // first run: create the file

        JsonAdapter {
            id: data
            property string accent: "#4fa3e6"
            property bool light: false
            property string wallpaper: ""
            property bool showTray: true
            property bool showMedia: true
            property bool batteryPercent: true
            property bool clockSeconds: false
            property string notifVertical: "top"
            property string notifHorizontal: "right"
            property int lockMinutes: 5
            property int screenOffMinutes: 5
            property int suspendMinutes: 15
            property int nightTemperature: 4000
            property string searchEngine: "google"
            property bool recordAudio: false
        }
    }
}
