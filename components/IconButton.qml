// Square icon button, in three sizes (Theme.control, controlSmall, controlTiny):
// normal (gray), primary (accent) or flat (no background; `on` makes the icon accent).
import QtQuick
import ".."

Rectangle {
    id: root
    property string icon
    property int size: Theme.control
    property bool primary: false
    property bool flat: false
    property bool on: false
    property bool filled: false
    property color iconColor: primary ? Theme.accentInk : on ? Theme.accent : flat ? Theme.textDim : Theme.text
    property int iconSize: size >= Theme.control ? Theme.icon
        : size >= Theme.controlSmall ? Theme.iconSmall : Theme.iconSmall
    signal clicked()

    implicitWidth: size
    implicitHeight: size
    radius: size >= Theme.control ? Theme.radiusControl : Theme.radiusSmall
    color: primary ? Theme.accent : flat ? "transparent" : Theme.surfaceHi
    opacity: enabled ? 1 : Theme.disabledOpacity

    Icon {
        anchors.centerIn: parent
        name: root.icon
        color: root.iconColor
        size: root.iconSize
        filled: root.filled
    }
    StateLayer { area: mouse; tint: root.iconColor }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
