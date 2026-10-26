// App icon: system icon theme (or image path), otherwise a gray square with the name's initial.
import Quickshell
import QtQuick
import ".."

Item {
    id: root
    property string icon       // theme icon name, image path or URL
    property string name       // for the fallback initial
    property int size: Theme.iconLarge

    readonly property string source: icon === "" ? ""
        : /^(\/|file:|image:|https?:)/.test(icon) ? (icon.startsWith("/") ? "file://" + icon : icon)
        : Quickshell.iconPath(icon, true)

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        visible: status === Image.Ready
    }
    Rectangle {
        visible: img.status !== Image.Ready
        anchors.fill: parent
        radius: Math.round(root.size / 4)
        color: Theme.surfaceHi
        Txt {
            anchors.centerIn: parent
            text: root.name.charAt(0).toUpperCase()
            font.pixelSize: Math.round(root.size * 0.55)
            font.weight: Font.Bold
        }
    }
}
