// Wallpaper picked in Settings, on every screen, below all windows.
// Without one, nothing is created: another wallpaper tool can take over.
import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

Variants {
    model: Settings.wallpaper !== "" ? Quickshell.screens : []

    PanelWindow {
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Theme.bg

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "simpleshell-wallpaper"

        Image {
            anchors.fill: parent
            source: "file://" + Settings.wallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(parent.width, parent.height)
        }
    }
}
