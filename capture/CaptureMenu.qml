// Capture menu (Print): screenshot of the screen, a region or a window; recording of the screen or a
// region, with or without sound. The menu fades out before the capture.
import QtQuick
import ".."
import "../components"
import "../services"

ActionMenu {
    id: menu
    name: "capture"
    open: Ui.captureOpen
    actions: [
        { icon: "monitor",       label: "Screen",        shot: "screen" },
        { icon: "scan",          label: "Region",        shot: "region" },
        { icon: "app-window",    label: "Window",        shot: "window" },
        { icon: "video",         label: "Record screen", record: "screen" },
        { icon: "square-dashed", label: "Record region", record: "region" }
    ]
    onPicked: (i) => {
        const a = actions[i];
        if (a.shot) Capture.screenshot(a.shot);
        else Capture.record(a.record);
    }
    onDismissed: Ui.captureOpen = false

    // Sound of the recordings (what the speakers play).
    Item {
        width: menu.buttonsWidth
        height: Theme.row
        Row {
            anchors { left: parent.left; leftMargin: Theme.rowPad; verticalCenter: parent.verticalCenter }
            spacing: Theme.iconGap
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Settings.recordAudio ? "volume-2" : "volume-x"
                color: Theme.textDim
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: "Record sound"
            }
        }
        Toggle {
            anchors { right: parent.right; rightMargin: Theme.rowPad; verticalCenter: parent.verticalCenter }
            checked: Settings.recordAudio
            onToggled: Settings.recordAudio = !Settings.recordAudio
        }
    }
}
