// Progress bar: volume, brightness, track. Fixed radius, never a pill.
import QtQuick
import ".."

Rectangle {
    id: root
    property real value: 0      // 0..1
    property bool muted: false
    property bool animated: false

    implicitHeight: Theme.trackHeight
    radius: Theme.radiusTrack
    color: Theme.surfaceHi
    Rectangle {
        height: parent.height
        width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.value)))
        radius: parent.radius
        color: root.muted ? Theme.textDim : Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.dur } }
        Behavior on width { enabled: root.animated; NumberAnimation { duration: Theme.durFast } }
    }
}
