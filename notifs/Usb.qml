// USB drives plugged in / removed: notifications sent by usb-watch.py (UDisks2), with an "Open"
// button. Restarted if it stops (D-Bus not ready yet at startup…).
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    Process {
        id: watch
        running: true
        command: ["python3", Quickshell.shellDir + "/notifs/usb-watch.py"]
        onExited: retry.start()
    }
    Timer { id: retry; interval: 5000; onTriggered: watch.running = true }
}
