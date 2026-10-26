// Last row of an expanded item: subtle detail on the left, "Forget" button on the right.
import QtQuick
import ".."

Item {
    id: info
    property string text
    property string buttonText: "Forget"
    signal clicked()

    width: parent ? parent.width : 0
    height: Theme.row
    Txt {
        anchors {
            left: parent.left; leftMargin: Theme.rowPad
            right: button.left; rightMargin: Theme.cardPad
            verticalCenter: parent.verticalCenter
        }
        text: info.text
        color: Theme.textDim
        font.pixelSize: Theme.fontSmall
    }
    TextButton {
        id: button
        anchors { right: parent.right; rightMargin: Theme.gap; verticalCenter: parent.verticalCenter }
        text: info.buttonText
        danger: true
        onClicked: info.clicked()
    }
}
