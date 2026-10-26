// Card holding a list of rows (networks, devices); shows `empty` when `count` is 0.
import QtQuick
import ".."

Rectangle {
    id: card
    property int count: 0
    property string empty: ""
    default property alias rows: column.data

    visible: count > 0 || empty !== ""
    implicitHeight: count > 0 ? column.implicitHeight : Theme.row
    radius: Theme.radius
    color: Theme.surface

    Txt {
        visible: card.count === 0
        anchors.centerIn: parent
        text: card.empty
        color: Theme.textDim
    }
    Column {
        id: column
        width: parent.width
    }
}
