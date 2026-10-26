// Stacked title and subtitle, wherever an item has a name and a state.
// strong: tile or card title (bold); otherwise a list row title.
// onAccent: drawn on an accent background.
import QtQuick
import ".."

Column {
    id: root
    property string title
    property string sub: ""
    property bool strong: false
    property bool onAccent: false
    property color subColor: onAccent ? Theme.accentInkDim : Theme.textDim

    spacing: Theme.tight
    Txt {
        width: parent.width
        text: root.title
        color: root.onAccent ? Theme.accentInk : Theme.text
        font.pixelSize: root.strong ? Theme.fontLarge : Theme.fontBody
        font.weight: root.strong ? Font.Bold : Font.Normal
    }
    Txt {
        width: parent.width
        visible: root.sub !== ""
        text: root.sub
        color: root.subColor
        font.pixelSize: Theme.fontSmall
    }
}
