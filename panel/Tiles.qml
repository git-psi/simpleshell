// The six tiles. Bluetooth and Power are loaded separately: if your Quickshell lacks the
// matching module, only that tile disappears.
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"

GridLayout {
    columns: 2
    columnSpacing: Theme.gap
    rowSpacing: Theme.gap

    Tile {
        Layout.fillWidth: true
        icon: Network.wifiOn ? "wifi" : "wifi-off"
        label: "Wi-Fi"
        sub: !Network.wifiOn ? "Off" : Network.connected ? Network.ssid : "Not connected"
        active: Network.wifiOn
        onClicked: Network.toggle()
        more: true
        onMoreClicked: Ui.panelPage = "wifi"
    }
    Loader {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.tile
        source: "BluetoothTile.qml"
    }
    Tile {
        Layout.fillWidth: true
        icon: Ui.dnd ? "bell-off" : "bell"
        label: "Do not disturb"
        active: Ui.dnd
        onClicked: Ui.dnd = !Ui.dnd
    }
    Tile {
        Layout.fillWidth: true
        icon: "moon"
        label: "Night light"
        active: Ui.nightLight
        onClicked: Ui.nightLight = !Ui.nightLight
    }
    Loader {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.tile
        source: "EnergyTile.qml"
    }
    Tile {
        Layout.fillWidth: true
        icon: "coffee"
        label: "Caffeine"
        active: Ui.caffeine
        onClicked: Ui.caffeine = !Ui.caffeine
    }
}
