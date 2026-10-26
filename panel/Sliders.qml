// Sliders card: brightness, volume, microphone. The volume (or mic) chevron expands, below the row,
// the output choice and each app's volume (or the input choice).
import Quickshell
import QtQuick
import ".."
import "../components"
import "../services"
import "../Format.js" as Format

Rectangle {
    id: root
    property string expanded: ""     // "sink", "source" or nothing

    implicitHeight: column.implicitHeight + Theme.cardPad * 2
    radius: Theme.radius
    color: Theme.surface

    Connections {
        target: Ui
        function onPanelOpenChanged() { if (!Ui.panelOpen) root.expanded = ""; }
    }

    Column {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.cardPad }
        spacing: Theme.inset

        ValueSlider {
            width: parent.width
            visible: Brightness.available
            icon: "sun"
            alignBars: true
            value: Brightness.value
            onMoved: (v) => Brightness.set(v)
        }

        ValueSlider {
            width: parent.width
            visible: Audio.sink !== null
            readonly property real vol: Audio.sink?.audio?.volume ?? 0
            muted: Audio.sink?.audio?.muted ?? false
            icon: Format.volumeIcon(vol, muted)
            value: vol
            expandable: true
            expanded: root.expanded === "sink"
            onMoved: (v) => Audio.setVolume(Audio.sink, v)
            onIconClicked: Audio.toggleMute(Audio.sink)
            onExpandClicked: root.expanded = expanded ? "" : "sink"
        }
        AudioDevices {
            visible: root.expanded === "sink"
            width: column.width
            title: "Output"
            devices: Audio.sinks
            current: Audio.sink

            SectionLabel {
                visible: Audio.apps.length > 0
                x: Theme.cardPad
                width: parent.width - Theme.cardPad * 2
                text: "Applications"
            }
            Repeater {
                model: ScriptModel { values: Audio.apps }
                ValueSlider {
                    required property var modelData
                    x: Theme.rowPad
                    width: parent.width - Theme.rowPad * 2
                    label: Audio.appName(modelData)
                    value: modelData.audio?.volume ?? 0
                    muted: modelData.audio?.muted ?? false
                    onMoved: (v) => Audio.setVolume(modelData, v)
                    onIconClicked: Audio.toggleMute(modelData)
                }
            }
        }

        ValueSlider {
            width: parent.width
            visible: Audio.source !== null
            muted: Audio.source?.audio?.muted ?? false
            icon: muted ? "mic-off" : "mic"
            value: Audio.source?.audio?.volume ?? 0
            expandable: true
            expanded: root.expanded === "source"
            onMoved: (v) => Audio.setVolume(Audio.source, v)
            onIconClicked: Audio.toggleMute(Audio.source)
            onExpandClicked: root.expanded = expanded ? "" : "source"
        }
        AudioDevices {
            visible: root.expanded === "source"
            width: column.width
            title: "Input"
            devices: Audio.sources
            current: Audio.source
        }
    }
}
