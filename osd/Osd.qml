// Base of the OSD bubbles at the bottom of the screen (keys, workspaces). Only one shown at a time
// (Ui.osdKind), none while the panel is open, and they take no clicks.
import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
import "../components"

PanelWindow {
    id: osd
    required property string kind
    property real cardWidth: Theme.osdWidth
    property int timeout: Theme.osdTimeout
    property bool shown: false
    property bool ready: false
    default property alias content: card.data

    screen: Ui.screen
    anchors.bottom: true
    margins.bottom: Theme.osdMargin
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.max(cardWidth, Theme.osdWidth)
    implicitHeight: Theme.row + Theme.gap * 2   // room for the small slide-in
    color: "transparent"
    mask: Region {}
    visible: shown || card.opacity > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simpleshell-osd"

    function show() {
        if (!ready || Ui.panelOpen) return;
        Ui.osdKind = kind;
        shown = true;
        hide.restart();
    }
    Connections {
        target: Ui
        function onOsdKindChanged() { if (Ui.osdKind !== osd.kind) osd.shown = false; }
    }

    // Avoids showing the OSD at startup, when the values come in.
    Timer { interval: 1500; running: true; onTriggered: osd.ready = true }
    Timer { id: hide; interval: osd.timeout; onTriggered: osd.shown = false }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: osd.cardWidth
        height: Theme.row
        radius: Theme.radius
        color: Theme.bg
        opacity: osd.shown ? 1 : 0
        anchors.verticalCenterOffset: osd.shown ? 0 : Theme.gap
        Behavior on opacity { id: fade; Anim { entering: fade.targetValue === 1 } }
        Behavior on anchors.verticalCenterOffset { id: rise; Anim { entering: rise.targetValue === 0 } }
        border.width: 1
        border.color: Theme.outline
    }
}
