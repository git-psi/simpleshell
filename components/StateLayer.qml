// Hover / press overlay, laid over a clickable element.
import QtQuick
import ".."

Rectangle {
    property MouseArea area
    property color tint: Theme.text
    anchors.fill: parent
    radius: parent.radius !== undefined ? parent.radius : 0
    color: tint
    opacity: !area ? 0 : area.pressed ? Theme.pressOpacity : area.containsMouse ? Theme.hoverOpacity : 0
    Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
}
