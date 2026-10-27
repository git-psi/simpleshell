pragma Singleton
// Bluetooth through BlueZ (Quickshell.Bluetooth module): adapter, device discovery while the page
// is open, and pairing agent (bt-agent.py) for codes to confirm.
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick
import ".."

Singleton {
    id: root
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked
    readonly property bool on: adapter?.enabled ?? false
    readonly property bool ready: adapter?.state === BluetoothAdapterState.Enabled
    readonly property var devices: adapter?.devices.values ?? []
    readonly property var connected: devices.find(d => d.connected) ?? null

    // Bluetooth page open: continuous discovery and pairing allowed. The page stays loaded when the
    // panel closes with a click outside: discovery only runs while the panel is open.
    property bool searching: false
    readonly property bool scanning: searching && Ui.panelOpen

    // Agent request: { type: "confirm" | "display", address, name, passkey }, or null.
    property var request: null

    function toggle() {
        if (!adapter) return;
        if (blocked) {
            Quickshell.execDetached(["rfkill", "unblock", "bluetooth"]);
            powerOn.restart();
        } else {
            adapter.enabled = !adapter.enabled;
        }
    }
    function answer(yes) {
        agent.write(yes ? "yes\n" : "no\n");
        request = null;
    }
    // Pair then connect: the device becomes trusted so it reconnects on its own.
    function pair(d) {
        d.trusted = true;
        d.pair();
    }

    // The rfkill block takes a moment to lift before the adapter can be powered on.
    Timer { id: powerOn; interval: 800; onTriggered: if (root.adapter) root.adapter.enabled = true }

    // BlueZ stops discovery when the adapter powers back on, after suspend or when another app
    // stops it: restart it while the page is open.
    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: root.scanning && root.ready
        onTriggered: {
            if (!root.adapter.pairable) root.adapter.pairable = true;
            if (!root.adapter.discovering) root.adapter.discovering = true;
        }
    }
    onScanningChanged: if (!scanning && adapter?.discovering) adapter.discovering = false

    Process {
        id: agent
        command: ["python3", Quickshell.shellDir + "/services/bt-agent.py"]
        running: root.available
        stdinEnabled: true
        stdout: SplitParser {
            onRead: (line) => {
                let msg;
                try { msg = JSON.parse(line); } catch (e) { return; }
                if (msg.type === "cancel") { root.request = null; return; }
                root.request = msg;
                // A request can come in while the panel is closed (device pairing on its own).
                Ui.closeAll();
                Ui.panelOpen = true;
                Ui.panelPage = "bluetooth";
            }
        }
        onStarted: startedAt = Date.now()
        onExited: {
            root.request = null;
            // A run of over a minute was a real run: the count starts over.
            if (Date.now() - startedAt > 60000) failures = 0;
            if (++failures <= 5) restart.start();
        }
        property real startedAt: 0
        property int failures: 0
    }
    // If the agent stops (bluetoothd restarted, error), restart it. Not forever if it can't start
    // (missing Python module): each attempt wakes the machine up.
    Timer { id: restart; interval: 3000; onTriggered: if (root.available) agent.running = true }
}
