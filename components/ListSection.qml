// List section: title above, card of rows (ListRow) below.
// Hidden when empty, unless showAlways (it then shows `empty`).
import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    id: section
    property string title
    property string empty: ""
    property int count: 0
    property bool showAlways: false
    default property alias rows: card.rows

    visible: count > 0 || showAlways
    Layout.fillWidth: true
    spacing: Theme.gap

    SectionLabel {
        Layout.fillWidth: true
        text: section.title
    }
    ListCard {
        id: card
        Layout.fillWidth: true
        count: section.count
        empty: section.empty
    }
}
