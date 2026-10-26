// List row, the same for Wi-Fi and Bluetooth: icon badge (accent when connected), title and
// state, action button on the right. Clicking the row (if expandable) expands it: whatever is
// declared inside then shows below, on a sunken background.
import QtQuick
import ".."

Item {
    id: row
    property string icon
    property bool active: false
    property string title
    property string sub: ""
    property bool failed: false          // subtitle in red
    property bool first: false           // no line above
    property bool expandable: false
    property bool open: false
    property bool chevron: false         // opens something else (instead of an action)
    property string actionText: ""
    property bool actionPrimary: false
    property bool actionDanger: false
    property bool actionEnabled: true
    default property alias details: drawer.data
    signal clicked()
    signal actionClicked()

    readonly property int innerRadius: Theme.inner(Theme.radius, Theme.inset)

    width: parent ? parent.width : 0
    height: open ? Theme.row + drawer.implicitHeight + Theme.inset : Theme.row

    Separator {
        visible: !row.first
        width: parent.width
    }
    Rectangle {
        visible: row.open
        anchors { fill: parent; margins: Theme.inset }
        radius: row.innerRadius
        color: Theme.sunken
    }

    Item {
        id: line
        width: parent.width
        height: Theme.row

        StateLayer { area: mouse; radius: row.innerRadius; anchors.margins: Theme.inset }
        MouseArea {
            id: mouse
            anchors.fill: parent
            enabled: row.expandable || row.chevron
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }

        Rectangle {
            id: badge
            anchors { left: parent.left; leftMargin: Theme.gap; verticalCenter: parent.verticalCenter }
            width: Theme.controlSmall; height: Theme.controlSmall
            radius: Theme.radiusSmall
            color: row.active ? Theme.accent : Theme.surfaceHi
            Behavior on color { ColorAnimation { duration: Theme.dur } }
            Icon {
                anchors.centerIn: parent
                name: row.icon
                size: Theme.iconSmall
                color: row.active ? Theme.accentInk : Theme.text
            }
        }
        TwoLines {
            anchors {
                left: badge.right; leftMargin: Theme.iconGap
                right: trailing.left; rightMargin: Theme.cardPad
                verticalCenter: parent.verticalCenter
            }
            title: row.title
            sub: row.sub
            subColor: row.failed ? Theme.danger : Theme.textDim
        }
        Item {
            id: trailing
            anchors { right: parent.right; rightMargin: row.chevron ? Theme.rowPad : Theme.gap; verticalCenter: parent.verticalCenter }
            width: row.chevron ? arrow.width : action.visible ? action.width : 0
            height: Theme.controlSmall
            Icon {
                id: arrow
                visible: row.chevron
                anchors.centerIn: parent
                name: "chevron-right"
                size: Theme.iconSmall
                color: Theme.textDim
            }
            TextButton {
                id: action
                visible: !row.chevron && row.actionText !== ""
                anchors.centerIn: parent
                text: row.actionText
                primary: row.actionPrimary
                danger: row.actionDanger
                enabled: row.actionEnabled
                onClicked: row.actionClicked()
            }
        }
    }

    Column {
        id: drawer
        visible: row.open
        y: Theme.row
        width: parent.width
    }
}
