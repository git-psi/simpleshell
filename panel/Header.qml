// Header: time, date, battery — on a single line.
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../Format.js" as Format

RowLayout {
    id: root
    spacing: Theme.cardPad

    SystemClock { id: clock; precision: Settings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes }

    readonly property var battery: UPower.displayDevice
    readonly property int percent: Format.percent(battery)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
        || battery?.state === UPowerDeviceState.FullyCharged

    Txt {
        text: Qt.formatTime(clock.date, Settings.clockSeconds ? "HH:mm:ss" : "HH:mm")
        font.pixelSize: Theme.fontTitle
        font.weight: Font.Bold
        Layout.alignment: Qt.AlignVCenter
    }
    Txt {
        text: clock.date.toLocaleDateString(Qt.locale("en_US"), "dddd, MMMM d")
        color: Theme.textDim
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
    }
    RowLayout {
        visible: root.battery?.isLaptopBattery ?? false
        spacing: Theme.inset
        Layout.alignment: Qt.AlignVCenter
        Txt {
            visible: Settings.batteryPercent
            text: root.percent + " %"
            font.pixelSize: Theme.fontSmall
            font.weight: Font.Medium
        }
        Icon {
            name: root.charging ? "battery-charging"
                : root.percent <= 15 ? "battery-low"
                : root.percent <= 60 ? "battery-medium" : "battery-full"
            color: root.percent <= 15 && !root.charging ? Theme.danger : Theme.text
        }
    }
}
