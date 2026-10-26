// Menu of big square buttons in the middle of the screen (power menu, capture menu), with optional
// content below them. Arrows or mouse to pick, Enter to confirm, Escape or click outside to close.
import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

PanelWindow {
    id: win
    required property bool open
    required property var actions          // [{ icon, label }]
    required property string name         // layer namespace: simpleshell-<name>
    property int current: 0
    readonly property real buttonsWidth: row.implicitWidth
    default property alias extra: below.data
    signal picked(int index)
    signal dismissed()                     // Escape, click outside

    screen: Ui.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: open || scrim.opacity > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simpleshell-" + name
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open) current = 0

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Theme.scrim
        opacity: win.open ? 1 : 0
        Behavior on opacity { id: fade; Anim { entering: fade.targetValue === 1 } }

        MouseArea {
            anchors.fill: parent
            onClicked: win.dismissed()
        }

        Rectangle {
            id: box
            readonly property int pad: Theme.gap
            anchors.centerIn: parent
            width: column.implicitWidth + pad * 2
            height: column.implicitHeight + pad * 2
            radius: Theme.radiusLarge
            color: Theme.bg
            border.width: 1
            border.color: Theme.outline
            // The frame settles while growing slightly, and leaves the same way (the backdrop fades with it).
            scale: win.open ? 1 : Theme.popFrom
            Behavior on scale { id: settle; Anim { entering: settle.targetValue === 1 } }

            focus: win.open
            Keys.onEscapePressed: win.dismissed()
            Keys.onLeftPressed: win.current = (win.current + win.actions.length - 1) % win.actions.length
            Keys.onRightPressed: win.current = (win.current + 1) % win.actions.length
            Keys.onTabPressed: win.current = (win.current + 1) % win.actions.length
            Keys.onReturnPressed: win.picked(win.current)
            Keys.onEnterPressed: win.picked(win.current)

            MouseArea { anchors.fill: parent }   // a click on the frame doesn't close the menu

            Column {
                id: column
                anchors.centerIn: parent

                Row {
                    id: row
                    spacing: Theme.gap

                    Repeater {
                        model: win.actions
                        delegate: Rectangle {
                            id: button
                            required property var modelData
                            required property int index
                            readonly property bool selected: win.current === index
                            readonly property color ink: selected ? Theme.accentInk : Theme.text

                            // Cascading entrance, left to right: each square grows in and appears,
                            // inside a fixed-size frame.
                            property real grow: 1
                            width: Theme.powerButton
                            height: Theme.powerButton
                            scale: grow
                            radius: Theme.inner(Theme.radiusLarge, box.pad)
                            color: selected ? Theme.accent : Theme.surface
                            Behavior on color { ColorAnimation { duration: Theme.dur } }

                            Connections {
                                target: win
                                function onOpenChanged() { if (win.open) intro.restart(); }
                            }
                            SequentialAnimation {
                                id: intro
                                PropertyAction { target: button; property: "opacity"; value: 0 }
                                PropertyAction { target: button; property: "grow"; value: Theme.popFrom }
                                PauseAnimation { duration: button.index * Theme.stagger }
                                ParallelAnimation {
                                    Anim { target: button; property: "grow"; to: 1; duration: Theme.durPop }
                                    Anim { target: button; property: "opacity"; to: 1 }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: Theme.iconGap
                                Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: button.modelData.icon
                                    size: Theme.iconLarge
                                    color: button.ink
                                }
                                Txt {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: button.modelData.label
                                    color: button.ink
                                    font.weight: Font.Medium
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: win.current = button.index
                                onClicked: win.picked(button.index)
                            }
                        }
                    }
                }

                Column { id: below }
            }
        }
    }
}
