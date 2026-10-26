// Section title above a card. Whatever is declared inside (a button…) goes to the right.
import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root
    property string text

    spacing: Theme.gap
    Txt {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.tight
        text: root.text
        color: Theme.textDim
        font.pixelSize: Theme.fontSmall
        font.weight: Font.Bold
    }
}
