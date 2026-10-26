// Background apps: each app's name, not its icon.
// Click: opens the app (or its menu if that's all it has). Right click: its menu.
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

ColumnLayout {
    id: root
    property var menu
    readonly property var items: SystemTray.items.values

    visible: items.length > 0 && Settings.showTray
    spacing: Theme.gap

    function nameOf(item) {
        const n = item.tooltipTitle || item.title || item.id || "?";
        return n.charAt(0).toUpperCase() + n.slice(1);
    }

    SectionLabel {
        Layout.fillWidth: true
        text: "Background"
    }

    Flow {
        Layout.fillWidth: true
        spacing: Theme.inset

        Repeater {
            model: root.items
            delegate: Rectangle {
                id: chip
                required property var modelData
                readonly property bool menuShown: root.menu.visible && root.menu.item === modelData

                width: label.implicitWidth + Theme.cardPad * 2
                height: Theme.controlTiny
                radius: Theme.radiusSmall
                color: menuShown ? Theme.accent : Theme.surface
                Behavior on color { ColorAnimation { duration: Theme.dur } }

                Txt {
                    id: label
                    anchors.centerIn: parent
                    text: root.nameOf(chip.modelData)
                    color: chip.menuShown ? Theme.accentInk : Theme.text
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                }
                StateLayer { area: chipMouse; tint: label.color }
                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        const it = chip.modelData;
                        if ((mouse.button === Qt.RightButton || it.onlyMenu) && it.hasMenu)
                            root.menu.toggle(it, chip);
                        else
                            it.activate();
                    }
                }
            }
        }
    }
}
