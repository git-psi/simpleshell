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
        // Not forever if it can't start (missing Python module): each attempt wakes the machine up.
        // A run of over a minute was a real run: the count starts over.
        onStarted: startedAt = Date.now()
        onExited: {
            if (Date.now() - startedAt > 60000) failures = 0;
            if (++failures <= 5) retry.start();
        }
        property real startedAt: 0
        property int failures: 0
    }
    Timer { id: retry; interval: 5000; onTriggered: watch.running = true }
}
