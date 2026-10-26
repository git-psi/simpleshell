// Choice between a few side-by-side options ("Dark | Light"): the chosen one is raised.
import QtQuick
import ".."

Rectangle {
    id: root
    property var options: []
    property int current: 0
    signal picked(int index)

    readonly property int pad: Theme.tight
    implicitWidth: row.implicitWidth + pad * 2
    implicitHeight: Theme.controlTiny
    radius: Theme.radiusSmall
    color: Theme.bg

    Row {
        id: row
        x: root.pad
        y: root.pad
        Repeater {
            model: root.options
            Rectangle {
                required property string modelData
                required property int index
                readonly property bool active: index === root.current
                width: label.implicitWidth + Theme.iconGap * 2
                height: root.height - root.pad * 2
                radius: Theme.inner(Theme.radiusSmall, root.pad)
                color: active ? Theme.surfaceHi : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.dur } }
                Txt {
                    id: label
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: parent.active ? Theme.text : Theme.textDim
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(parent.index)
                }
            }
        }
    }
}
