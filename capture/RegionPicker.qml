// Area picker of the screenshots and recordings: drag a region, or click a window (highlighted under
// the cursor). Over the frozen screen for a screenshot, the live one for a recording. Escape or a
// right click cancels.
import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
import "../components"
import "../services"

PanelWindow {
    id: win
    readonly property bool open: Capture.picking !== ""
    readonly property bool onlyWindows: Capture.picking === "window"
    readonly property bool still: Capture.picking !== "record"
    readonly property real pixelRatio: still && frozen.implicitWidth > 0 ? frozen.implicitWidth / width : 1
    // Selection, in screen coordinates; empty: none yet.
    property rect area: Qt.rect(0, 0, 0, 0)
    property string windowId: ""          // the selection is this window (Hyprland stableId)
    property point start
    property bool dragging: false

    screen: Capture.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simpleshell-picker"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: {
        area = Qt.rect(0, 0, 0, 0);
        windowId = "";
        dragging = false;
    }

    // Selects the window under the cursor (cut to the screen), or nothing.
    function selectWindow(x, y) {
        const w = Capture.windows.find(r => x >= r[0] && x < r[0] + r[2] && y >= r[1] && y < r[1] + r[3]);
        windowId = w ? w[4] : "";
        if (!w) {
            area = Qt.rect(0, 0, 0, 0);
            return;
        }
        const x0 = Math.max(0, w[0]), y0 = Math.max(0, w[1]);
        area = Qt.rect(x0, y0, Math.min(width, w[0] + w[2]) - x0, Math.min(height, w[1] + w[3]) - y0);
    }
    function done() {
        if (area.width < 2 || area.height < 2) return;   // nothing under the click: keep picking
        // A window's screenshot is the window alone, without what covers it (notifications…).
        if (windowId !== "" && still) Capture.pickedWindow(windowId);
        else Capture.picked(area.x, area.y, area.width, area.height, pixelRatio);
    }

    Image {
        id: frozen
        anchors.fill: parent
        visible: win.still
        // The query only changes the address: a new freeze is read again.
        source: win.still && win.open ? "file://" + Capture.frozenPath + "?" + Capture.frozenAt : ""
        cache: false
        smooth: true
    }

    // Dimmed outside the selection.
    Item {
        anchors.fill: parent
        readonly property rect a: win.area
        readonly property bool any: a.width > 0
        Rectangle { color: Theme.scrim; width: parent.width; height: parent.any ? parent.a.y : parent.height }
        Rectangle {
            visible: parent.any
            color: Theme.scrim
            y: parent.a.y + parent.a.height
            width: parent.width
            height: parent.height - y
        }
        Rectangle {
            visible: parent.any
            color: Theme.scrim
            y: parent.a.y
            width: parent.a.x
            height: parent.a.height
        }
        Rectangle {
            visible: parent.any
            color: Theme.scrim
            x: parent.a.x + parent.a.width
            y: parent.a.y
            width: parent.width - x
            height: parent.a.height
        }
        // Square border: it shows exactly what is captured.
        Rectangle {
            visible: parent.any
            x: parent.a.x - border.width
            y: parent.a.y - border.width
            width: parent.a.width + border.width * 2
            height: parent.a.height + border.width * 2
            color: "transparent"
            border.width: 2
            border.color: Theme.accent
        }
    }

    // Size of the selection in pixels: below it, above it if there's no room, else inside.
    Chip {
        visible: win.area.width > 0
        text: Math.round(win.area.width * win.pixelRatio) + " × " + Math.round(win.area.height * win.pixelRatio)
        x: Math.min(win.area.x, win.width - width)
        y: {
            const below = win.area.y + win.area.height + Theme.gap;
            const above = win.area.y - height - Theme.gap;
            return below + height <= win.height ? below : above >= 0 ? above : win.area.y + Theme.gap;
        }
    }
    // What to do, until something is selected.
    Chip {
        visible: win.area.width === 0
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.screenMargin }
        text: (win.onlyWindows ? "Click a window" : "Drag to select an area, or click a window")
            + " - Esc to cancel"
    }

    Item {
        anchors.fill: parent
        focus: win.open
        Keys.onEscapePressed: Capture.cancel()

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.CrossCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: (m) => {
                if (m.button === Qt.RightButton) {
                    Capture.cancel();
                    return;
                }
                win.start = Qt.point(m.x, m.y);
            }
            onPositionChanged: (m) => {
                if (!pressed) {
                    win.selectWindow(m.x, m.y);
                    return;
                }
                // A few pixels before it's a drag rather than a click.
                if (!win.onlyWindows && (win.dragging || Math.abs(m.x - win.start.x) > 4
                                         || Math.abs(m.y - win.start.y) > 4)) {
                    win.dragging = true;
                    win.windowId = "";
                    const x = Math.max(0, Math.min(m.x, win.width)), y = Math.max(0, Math.min(m.y, win.height));
                    win.area = Qt.rect(Math.round(Math.min(x, win.start.x)), Math.round(Math.min(y, win.start.y)),
                                       Math.round(Math.abs(x - win.start.x)), Math.round(Math.abs(y - win.start.y)));
                }
            }
            onReleased: (m) => {
                if (m.button !== Qt.LeftButton) return;
                if (!win.dragging) win.selectWindow(m.x, m.y);
                win.dragging = false;
                win.done();
            }
        }
    }

    component Chip: Rectangle {
        property alias text: label.text
        width: label.implicitWidth + Theme.rowPad * 2
        height: Theme.controlSmall
        radius: Theme.radiusSmall
        color: Theme.bg
        border.width: 1
        border.color: Theme.outline
        Txt {
            id: label
            anchors.centerIn: parent
            font.weight: Font.Medium
            font.features: ({ "tnum": 1 })
        }
    }
}
