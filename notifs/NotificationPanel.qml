// Notification panel (Super+N): against the left edge, full height, slides in from the left.
// Title, clear all, Do not disturb, then the notifications.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"

PanelWindow {
    id: win
    readonly property bool open: Ui.notifsOpen

    screen: Ui.screen
    anchors { top: true; left: true; bottom: true }
    implicitWidth: Theme.panelWidth
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: open || sheet.x > -Theme.panelWidth

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simpleshell-notifications"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // A click outside the panel closes it.
    HyprlandFocusGrab {
        windows: [win]
        active: win.open
        onCleared: Ui.notifsOpen = false
    }

    Rectangle {
        id: sheet
        width: Theme.panelWidth
        height: parent.height
        color: Theme.bg
        x: win.open ? 0 : -Theme.panelWidth

        // Outline on the inner edge, like floating elements.
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.outline }
        Behavior on x { id: slide; Anim { drawer: true; entering: slide.targetValue === 0 } }

        focus: win.open
        Keys.onEscapePressed: Ui.notifsOpen = false

        ColumnLayout {
            anchors { fill: parent; margins: Theme.panelPad }
            spacing: Theme.section

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.iconGap
                Txt {
                    text: "Notifications"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                }
                Item { Layout.fillWidth: true }
                IconButton {
                    visible: Notifs.count > 0
                    size: Theme.controlSmall
                    icon: "trash-2"
                    iconColor: Theme.danger
                    onClicked: Notifs.clear()
                }
                IconButton {
                    size: Theme.controlSmall
                    primary: Ui.dnd
                    icon: Ui.dnd ? "bell-off" : "bell"
                    onClicked: Ui.dnd = !Ui.dnd
                }
            }

            Flickable {
                visible: Notifs.count > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: list.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: list
                    width: parent.width
                    spacing: Theme.gap
                    Repeater {
                        model: ScriptModel { values: Notifs.list }
                        NotificationCard {
                            required property var modelData
                            width: list.width
                            notification: modelData
                            onActivated: Ui.notifsOpen = false
                        }
                    }
                }
            }

            Item {
                visible: Notifs.count === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Txt {
                    anchors.centerIn: parent
                    text: "No notifications"
                    color: Theme.textDim
                }
            }
        }
    }
}
