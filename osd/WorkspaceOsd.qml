// OSD at the same place as the volume one, when switching workspaces (the screen's open
// workspaces, the current one in accent) or opening a scratchpad (its name).
import Quickshell
import Quickshell.Hyprland
import QtQuick
import ".."
import "../components"

Osd {
    id: osd
    property string special: ""   // open scratchpad, empty = workspace list

    readonly property var monitor: Hyprland.focusedMonitor
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(w => w.id > 0 && w.monitor?.name === monitor?.name)
        .sort((a, b) => a.id - b.id)

    kind: "workspace"
    cardWidth: special !== "" ? scratch.implicitWidth + Theme.rowPad * 2 : desks.implicitWidth + Theme.gap * 2

    function showDesk(name) {
        special = name;
        show();
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspacev2") osd.showDesk("");
            // "activespecial>>special:term,DP-1"; empty name when it closes: nothing to show.
            else if (event.name === "activespecial") {
                // Name as the user wrote it in their config; "my-notes" → "My notes".
                const name = event.data.split(",")[0].replace(/^special:/, "").replace(/[-_]+/g, " ").trim();
                if (name !== "") osd.showDesk(name.charAt(0).toUpperCase() + name.slice(1));
            }
        }
    }

    // Open workspaces: one numbered square each, gray number if the workspace is empty.
    Row {
        id: desks
        visible: osd.special === ""
        anchors.centerIn: parent
        spacing: Theme.inset
        Repeater {
            model: osd.workspaces
            Rectangle {
                required property var modelData
                readonly property bool current: modelData.id === osd.monitor?.activeWorkspace?.id
                width: Theme.controlSmall
                height: Theme.controlSmall
                radius: Theme.inner(Theme.radius, Theme.gap)
                color: current ? Theme.accent : Theme.surfaceHi
                Txt {
                    anchors.centerIn: parent
                    text: parent.modelData.name
                    color: parent.current ? Theme.accentInk
                        : parent.modelData.toplevels.values.length > 0 ? Theme.text : Theme.textDim
                    font.weight: Font.Bold
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }

    // Open scratchpad: its name.
    Row {
        id: scratch
        visible: osd.special !== ""
        anchors.centerIn: parent
        spacing: Theme.iconGap
        Icon { name: "layers"; anchors.verticalCenter: parent.verticalCenter }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: osd.special
            font.weight: Font.Bold
        }
    }
}
