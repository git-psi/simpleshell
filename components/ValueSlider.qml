// Slider row: icon (click = mute) or name, bar, and optionally a chevron (right = closed,
// down = open) that expands more settings below.
import QtQuick
import ".."

Item {
    id: root
    property string icon: ""        // Lucide icon; otherwise `label` is shown instead
    property string label: ""
    property real value: 0          // 0..1
    property bool muted: false
    property bool expandable: false
    property bool expanded: false
    property bool alignBars: false  // keep the chevron's room, to line up with rows that have one
    property real innerRadius: Theme.inner(Theme.radius, Theme.cardPad)   // of the card holding it
    signal moved(real value)
    signal iconClicked()
    signal expandClicked()

    implicitHeight: Theme.controlTiny
    readonly property bool trailing: expandable || alignBars

    function clamp(v) { return Math.max(0, Math.min(1, v)); }

    Rectangle {
        id: iconBox
        visible: root.icon !== ""
        width: Theme.controlTiny; height: Theme.controlTiny
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        radius: root.innerRadius
        color: "transparent"
        Icon {
            anchors.centerIn: parent
            name: root.icon
            color: root.muted ? Theme.textDim : Theme.text
        }
        StateLayer { area: iconMouse }
        MouseArea {
            id: iconMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }
    Txt {
        id: name
        visible: root.icon === ""
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: Theme.labelWidth
        text: root.label
        color: root.muted ? Theme.textDim : Theme.text
        font.weight: Font.Medium
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Item {
        anchors {
            left: iconBox.visible ? iconBox.right : name.right; leftMargin: Theme.cardPad
            right: root.trailing ? chevron.left : parent.right
            rightMargin: root.trailing ? Theme.inset : 0
            verticalCenter: parent.verticalCenter
        }
        height: Theme.controlTiny

        Bar {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            value: root.value
            muted: root.muted
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            function apply(x) { root.moved(root.clamp(x / width)); }
            onPressed: (mouse) => apply(mouse.x)
            onPositionChanged: (mouse) => { if (pressed) apply(mouse.x); }
            onWheel: (wheel) => root.moved(root.clamp(root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
        }
    }

    IconButton {
        id: chevron
        visible: root.expandable
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        size: Theme.controlTiny
        radius: root.innerRadius
        flat: true
        icon: root.expanded ? "chevron-down" : "chevron-right"
        onClicked: root.expandClicked()
    }
}
