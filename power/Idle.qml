// Lock, screens off and suspend when idle: delays from Settings. Writes
// ~/.local/state/simpleshell/hypridle.conf (hypr/hypridle.conf + the delays) and restarts hypridle on
// it, detached: it survives a shell restart.
import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Scope {
    id: root
    readonly property string path: Settings.dir + "/hypridle.conf"
    readonly property string dpms: "hyprctl dispatch 'hl.dsp.dpms({ action = \"%1\" })'"

    function listener(seconds, timeout, resume) {
        return "\nlistener {\n    timeout = " + seconds + "\n    on-timeout = " + timeout
            + (resume ? "\n    on-resume = " + resume : "") + "\n}\n";
    }

    readonly property string text: {
        const lock = Settings.lockMinutes * 60;
        let off = Settings.screenOffMinutes * 60;
        // Screens off at the same time as the lock: let the lock screen show first.
        if (lock > 0 && off > 0 && off <= lock) off = lock + 30;
        let t = "# Written by simpleshell (power/Idle.qml): delays picked in Settings > Idle.\n"
            + "source = " + Quickshell.shellDir + "/hypr/hypridle.conf\n";
        if (lock > 0) t += listener(lock, "loginctl lock-session");
        if (off > 0) t += listener(off, dpms.arg("disable"), dpms.arg("enable"));
        if (Settings.suspendMinutes > 0) t += listener(Settings.suspendMinutes * 60, "systemctl suspend");
        return t;
    }

    // Groups close changes, and waits for the real settings (not the defaults).
    onTextChanged: if (Settings.loaded) apply.restart()
    Component.onCompleted: if (Settings.loaded) apply.restart()   // shell reload
    Connections {
        target: Settings
        function onLoadedChanged() { if (Settings.loaded) apply.restart(); }
    }
    // File written first (blockWrites), then hypridle restarted, even if the text didn't change:
    // at login, it isn't running yet. flock: never two hypridle at once.
    Timer {
        id: apply
        interval: 300
        onTriggered: {
            file.setText(root.text);
            Quickshell.execDetached(["flock", "-o", root.path + ".lock", "sh", "-c",
                "pkill -x hypridle; while pgrep -x hypridle >/dev/null; do sleep 0.1; done; setsid hypridle -q -c \"$1\" &",
                "sh", root.path]);
        }
    }
    FileView {
        id: file
        path: Settings.loaded ? root.path : ""
        blockWrites: true
        printErrors: false   // first run: the file doesn't exist yet
    }
}
