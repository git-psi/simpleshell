// Lucide icon (components/lucide/<name>.svg) recolored on the fly: the file is read and the SVG
// regenerated with the right color and stroke width.
import Quickshell.Io
import QtQuick
import ".."
import "Icons.js" as Icons

Item {
    id: root
    property string name
    property color color: Theme.text
    property real size: Theme.icon
    property real stroke: 2
    property bool filled: false
    property string body: ""

    implicitWidth: size
    implicitHeight: size

    FileView {
        path: root.name === "" ? "" : Qt.resolvedUrl("lucide/" + root.name + ".svg").toString().replace("file://", "")
        blockLoading: true
        onLoaded: root.body = Icons.body(text())
        onLoadFailed: root.body = ""
    }

    Image {
        anchors.fill: parent
        sourceSize: Qt.size(root.size, root.size)
        smooth: true
        source: root.body === "" ? ""
            : Icons.url(root.body, root.color.r, root.color.g, root.color.b, root.color.a, root.stroke, root.filled)
    }
}
