// Quick panel tile: icon, title and subtitle; accent-colored when active.
import QtQuick
import ".."

Rectangle {
    id: root
    property string icon
    property string label
    property string sub: ""
    property bool active: false
    property bool more: false       // chevron on the right: opens the details
    signal clicked()
    signal moreClicked()

    readonly property color ink: active ? Theme.accentInk : Theme.text

    implicitHeight: Theme.tile
    radius: Theme.radius
    color: active ? Theme.accent : Theme.surface
    Behavior on color { ColorAnimation { duration: Theme.dur } }

    Icon {
        id: glyph
        anchors { left: parent.left; leftMargin: Theme.rowPad; verticalCenter: parent.verticalCenter }
        name: root.icon
        color: root.ink
    }
    TwoLines {
        anchors {
            left: glyph.right; leftMargin: Theme.iconGap
            right: root.more ? chevron.left : parent.right; rightMargin: root.more ? Theme.inset : Theme.iconGap
            verticalCenter: parent.verticalCenter
        }
        title: root.label
        sub: root.sub
        strong: true
        onAccent: root.active
    }
    StateLayer { area: mouse; tint: root.ink }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // 8 px inset: radius = 14 − 8, like the 32 px button inside a row.
    IconButton {
        id: chevron
        visible: root.more
        anchors { right: parent.right; rightMargin: Theme.gap; verticalCenter: parent.verticalCenter }
        size: Theme.controlSmall
        height: parent.height - Theme.gap * 2
        radius: Theme.inner(Theme.radius, Theme.gap)
        flat: true
        icon: "chevron-right"
        iconColor: root.ink
        onClicked: root.moreClicked()
    }
}
