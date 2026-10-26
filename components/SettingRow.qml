// Setting row in a card: label (and detail below) on the left, the control on the right (whatever
// is declared inside). Line above except for the first row.
// clickable: the whole row reacts (clicked), like "Open" in Settings.
import QtQuick
import ".."

Item {
    id: row
    property string text
    property string sub: ""
    property bool first: false
    property bool clickable: false
    default property alias trailing: slot.data
    signal clicked()

    width: parent ? parent.width : 0
    height: Theme.row

    Separator {
        visible: !row.first
        width: parent.width
    }
    StateLayer { area: mouse; radius: Theme.inner(Theme.radius, Theme.inset); anchors.margins: Theme.inset }
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: row.clickable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }
    TwoLines {
        anchors {
            left: parent.left; leftMargin: Theme.rowPad
            right: slot.left; rightMargin: Theme.cardPad
            verticalCenter: parent.verticalCenter
        }
        title: row.text
        sub: row.sub
    }
    Item {
        id: slot
        anchors { right: parent.right; rightMargin: Theme.rowPad; verticalCenter: parent.verticalCenter }
        width: childrenRect.width
        height: childrenRect.height
    }
}
