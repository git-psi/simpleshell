// Switch: rounded corners, never a pill.
import QtQuick
import ".."

Rectangle {
    id: root
    property bool checked: false
    signal toggled()

    readonly property int pad: 3
    implicitWidth: Theme.toggleWidth
    implicitHeight: Theme.toggleHeight
    radius: Theme.radiusSmall
    color: checked ? Theme.accent : Theme.surfaceHi
    Behavior on color { ColorAnimation { duration: Theme.dur } }

    Rectangle {
        width: parent.height - root.pad * 2
        height: width
        y: root.pad
        x: root.checked ? parent.width - width - root.pad : root.pad
        radius: Theme.inner(Theme.radiusSmall, root.pad)
        color: root.checked ? Theme.accentInk : Theme.textDim
        Behavior on x { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveOut } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
