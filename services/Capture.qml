pragma Singleton
// Screenshots and screen recordings. The screen is frozen (grim) before the capture menu opens: the
// menu is never in the picture, and the area is picked on a still screen (capture/RegionPicker.qml).
// capture/capture.sh saves, copies and notifies. Recording: area, 3-2-1 countdown, then wf-recorder,
// stopped by Print / Super+Shift+S or from the panel.
import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Singleton {
    id: root
    // Recording, or about to (area being picked, countdown): the shortcut stops / cancels it.
    readonly property bool busy: recorder.running || countdown > 0 || go.running || picking === "record"
    property bool recording: false
    property int countdown: 0         // 3, 2, 1 before recording (capture/CaptureOsd.qml); 0 otherwise
    property int elapsed: 0           // recording time, in seconds

    // Area picker open: "region", "window" (screenshot, frozen screen) or "record" (live screen).
    property string picking: ""
    property var screen: Ui.screen    // screen being captured
    property bool frozen: false       // frozenPath holds that screen
    property int frozenAt: 0          // changes with each freeze: the picker reloads the image
    readonly property string frozenPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/simpleshell-capture.ppm"
    // Windows shown on that screen, [x, y, w, h, stableId] in its coordinates, the ones on top first.
    property var windows: []
    property string next: ""          // what to do once frozen
    property var area: []             // wf-recorder's area: -o OUTPUT or -g "X,Y WxH"

    readonly property string script: Quickshell.shellDir + "/capture/capture.sh"

    // Print, Super+Shift+S: the capture menu; again with the menu open, the whole screen; while
    // recording, stop; while picking an area, cancel.
    function key() {
        if (busy) stop();
        else if (picking !== "") cancel();
        else if (Ui.captureOpen) screenshot("screen");
        else freeze("menu");
    }
    // screen, region or window.
    function screenshot(mode) {
        if (Ui.captureOpen && frozen) use(mode);
        else freeze(mode);
    }
    function record(mode) {
        if (busy) return;
        Ui.closeAll();
        screen = Ui.screen;
        if (mode === "region") {
            listWindows();
            picking = "record";
        } else {
            countDown(["-o", screen.name]);
        }
    }
    // Stops the recording, or cancels it while picking the area / counting down.
    function stop() {
        if (picking === "record") picking = "";
        countdown = 0;
        go.stop();
        if (!recording) tick.stop();
        if (recorder.running) recorder.signal(15);   // SIGTERM: capture.sh lets wf-recorder finish the file
    }

    // Area picked (RegionPicker), in screen coordinates; scale: pixels of the frozen image per point.
    function picked(x, y, w, h, scale) {
        const mode = picking;
        picking = "";
        if (mode === "record") {
            // H.264 in yuv420p (plays everywhere) needs an even width and height.
            const even = v => Math.floor(v / 2) * 2;
            countDown(["-g", (screen.x + x) + "," + (screen.y + y) + " " + even(w) + "x" + even(h)]);
        } else {
            const crop = [x, y, w, h].map(v => String(Math.round(v * scale)));
            Quickshell.execDetached([script, "shot", frozenPath].concat(crop));
        }
    }
    // Window clicked for a screenshot: captured on its own (grim -T).
    function pickedWindow(id) {
        picking = "";
        Quickshell.execDetached([script, "window", id]);
    }
    function cancel() { picking = ""; }

    // A panel or menu open would be in the picture: it fades out first.
    function freeze(then) {
        next = then;
        frozen = false;
        if (Ui.panelOpen || Ui.notifsOpen || Ui.launcherOpen || Ui.powerOpen) {
            Ui.closeAll();
            later.restart();
        } else {
            grab();
        }
    }
    Timer { id: later; interval: Theme.durDrawerOut + 100; onTriggered: root.grab() }
    function grab() {
        screen = Ui.screen;
        grim.command = ["grim", "-t", "ppm", "-o", screen.name, frozenPath];   // ppm: no compression, fast
        grim.running = true;
        listWindows();
    }
    Process {
        id: grim
        onExited: (code) => {
            if (code !== 0) return;
            root.frozen = true;
            root.frozenAt++;
            root.use(root.next);
        }
    }
    function use(mode) {
        Ui.closeAll();
        if (mode === "menu") Ui.captureOpen = true;
        else if (mode === "screen") Quickshell.execDetached([script, "shot", frozenPath]);
        else picking = mode;
    }

    // Windows to click in the picker: active workspace and open special workspace of the screen.
    function listWindows() { monitors.running = true; }
    Process {
        id: monitors
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                clients.monitor = JSON.parse(text).find(m => m.name === root.screen.name) ?? null;
                clients.running = true;
            }
        }
    }
    Process {
        id: clients
        property var monitor: null
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = clients.monitor;
                if (!m) { root.windows = []; return; }
                const shown = [m.activeWorkspace.id, m.specialWorkspace.id];
                root.windows = JSON.parse(text)
                    .filter(c => c.mapped && !c.hidden && shown.includes(c.workspace.id))
                    .sort((a, b) => (b.workspace.id < 0) - (a.workspace.id < 0) || b.floating - a.floating)
                    .map(c => [c.at[0] - m.x, c.at[1] - m.y, c.size[0], c.size[1], String(c.stableId)]);
            }
        }
    }

    function countDown(area) {
        root.area = area;
        countdown = 3;
        tick.restart();
    }
    // Countdown, then the recording's clock.
    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.recording) {
                root.elapsed++;
            } else if (root.countdown > 1) {
                root.countdown--;
            } else {
                root.countdown = 0;
                tick.stop();
                go.restart();
            }
        }
    }
    // The countdown bubble fades out before recording starts.
    Timer {
        id: go
        interval: Theme.durOut + 120
        onTriggered: {
            recorder.command = [root.script, "record", Settings.recordAudio ? "1" : "0"].concat(root.area);
            recorder.running = true;
        }
    }
    Process {
        id: recorder
        stdout: SplitParser {
            onRead: (line) => {
                if (line !== "recording") return;
                root.elapsed = 0;
                root.recording = true;
                tick.restart();
            }
        }
        onExited: {
            root.recording = false;
            tick.stop();
        }
    }
}
