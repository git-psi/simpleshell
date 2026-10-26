// Header of a panel page: back to home, title, switch (optional).
import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root
    property string title
    property bool checked: false
    property bool showToggle: true
    signal toggled()

    spacing: Theme.iconGap
    IconButton {
        size: Theme.controlSmall
        icon: "chevron-left"
        onClicked: Ui.back()
    }
    Txt {
        Layout.fillWidth: true
        text: root.title
        font.pixelSize: Theme.fontTitle
        font.weight: Font.Bold
    }
    Toggle {
        visible: root.showToggle
        checked: root.checked
        onToggled: root.toggled()
    }
}
