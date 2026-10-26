// Bluetooth tile (loaded separately by Tiles.qml: missing if Quickshell lacks the module).
import QtQuick
import ".."
import "../components"
import "../services"
import "../Format.js" as Format

Tile {
    icon: Bt.on ? "bluetooth" : "bluetooth-off"
    label: "Bluetooth"
    sub: !Bt.available ? "No adapter"
        : Bt.blocked ? "Blocked"
        : !Bt.on ? "Off"
        : Bt.connected ? Format.btName(Bt.connected) : "No device"
    active: Bt.on
    onClicked: Bt.toggle()
    more: Bt.available
    onMoreClicked: Ui.panelPage = "bluetooth"
}
