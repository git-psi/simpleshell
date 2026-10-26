pragma Singleton
// Brightness of all screens: backlight (brightnessctl) and external displays (ddcutil, DDC/CI).
// With neither, the row hides.
import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Singleton {
    id: root
    readonly property bool available: backlight || displays.length > 0
    property bool backlight: false
    property var displays: []   // I2C buses of external displays (ddcutil)
    property real value: 0      // 0..1

    function refresh() { reader.running = true; }
    function set(v) {
        root.value = Math.max(0.01, Math.min(1, v));
        writer.restart();
    }
    function step(delta) { set(value + delta); }

    // Quick bar movements are grouped into a single command.
    Timer {
        id: writer
        interval: 50
        onTriggered: {
            const pct = Math.round(root.value * 100);
            if (root.backlight)
                Quickshell.execDetached(["brightnessctl", "-q", "set", pct + "%"]);
            // DDC is slow: one write at a time, the last value wins.
            if (root.displays.length > 0) {
                if (ddcWriter.running) ddcRetry.restart();
                else ddcWriter.running = true;
            }
        }
    }
    Timer { id: ddcRetry; interval: 40; onTriggered: writer.triggered() }
    Process {
        id: ddcWriter
        command: ["sh", "-c", root.displays.map(d =>
            "ddcutil --noverify --skip-ddc-checks --sleep-multiplier 0.1 --bus " + d + " setvcp 10 " + Math.round(root.value * 100)).join(" ; ")]
    }

    Process {
        id: reader
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        // output: name,class,current,percent,max
        stdout: StdioCollector {
            id: readerOut
            onStreamFinished: {
                const f = readerOut.text.trim().split(",");
                root.backlight = f.length >= 5 && parseInt(f[4]) > 0;
                if (root.backlight) root.value = parseInt(f[2]) / parseInt(f[4]);
                else if (root.displays.length > 0) ddcReader.running = true;
            }
        }
        onExited: (code) => { if (code !== 0) root.backlight = false; }
    }
    Process {
        id: ddcReader
        command: ["ddcutil", "--bus", String(root.displays[0] ?? 0), "-t", "getvcp", "10"]
        // output: VCP 10 C <current> <max>
        stdout: StdioCollector {
            id: ddcReaderOut
            onStreamFinished: {
                const f = ddcReaderOut.text.trim().split(/\s+/);
                if (f.length >= 5 && parseInt(f[4]) > 0) root.value = parseInt(f[3]) / parseInt(f[4]);
            }
        }
    }
    Process {
        id: detector
        command: ["ddcutil", "detect", "-t"]
        stdout: StdioCollector {
            id: detectorOut
            onStreamFinished: {
                // I2C bus of each valid display ("Invalid display" blocks are skipped).
                const blocks = detectorOut.text.split(/\n(?=\S)/).filter(b => /^Display \d+/.test(b));
                root.displays = blocks.map(b => (b.match(/i2c-(\d+)/) ?? [])[1]).filter(n => n !== undefined).map(Number);
                root.refresh();
            }
        }
    }

    // Re-read the value each time the panel opens.
    Connections {
        target: Ui
        function onPanelOpenChanged() { if (Ui.panelOpen) root.refresh(); }
    }
    Component.onCompleted: { refresh(); detector.running = true; }
}
