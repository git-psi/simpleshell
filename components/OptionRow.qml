// Yes / no setting: label and switch.
import QtQuick
import ".."

SettingRow {
    id: opt
    property bool checked
    signal toggled()
    first: true   // in an expanded list, no line between options

    Toggle {
        checked: opt.checked
        onToggled: opt.toggled()
    }
}
