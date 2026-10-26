// Settings group: section title and a card stacking the rows (SettingRow).
import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    id: group
    property string title
    default property alias rows: card.data

    Layout.fillWidth: true
    spacing: Theme.gap
    SectionLabel {
        Layout.fillWidth: true
        text: group.title
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: card.implicitHeight
        radius: Theme.radius
        color: Theme.surface
        Column {
            id: card
            width: parent.width
        }
    }
}
