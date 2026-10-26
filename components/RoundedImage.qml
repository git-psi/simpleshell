// Image cropped to rounded corners (cover art, screenshot preview).
import QtQuick
import QtQuick.Effects
import ".."

Item {
    id: root
    property alias source: img.source
    property real radius: Theme.radiusSmall
    readonly property bool ready: img.status === Image.Ready

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        visible: root.ready
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }
}
