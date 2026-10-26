// Text button: secondary (gray), primary (accent) or destructive (red text).
import QtQuick
import ".."

Rectangle {
    id: btn
    property string text
    property bool primary: false
    property bool danger: false
    signal clicked()

    implicitWidth: label.implicitWidth + Theme.rowPad * 2
    implicitHeight: Theme.controlSmall
    width: implicitWidth
    height: implicitHeight
    radius: Theme.radiusSmall
    color: primary ? Theme.accent : Theme.surfaceHi
    opacity: enabled ? 1 : Theme.disabledOpacity

    Txt {
        id: label
        anchors.centerIn: parent
        text: btn.text
        color: btn.primary ? Theme.accentInk : btn.danger ? Theme.danger : Theme.text
        font.weight: Font.Medium
    }
    StateLayer { area: btnMouse; tint: label.color }
    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
