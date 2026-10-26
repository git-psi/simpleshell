// Base text: the theme's regular font and size.
import QtQuick
import ".."

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontBody
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
