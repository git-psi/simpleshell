// Battery reminders: a notification at 20%, a critical one at 10% (it goes through Do not disturb
// and stays on screen). Nothing while plugged in; plugging in resets the reminders.
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "../Format.js" as Format

Scope {
    id: root
    readonly property var battery: UPower.displayDevice
    readonly property bool present: battery?.isLaptopBattery ?? false
    readonly property int percent: Format.percent(battery)
    readonly property var levels: [20, 10]
    property int warned: 101   // lowest level already reported

    function check() {
        if (!present || !battery.ready) return;
        if (!UPower.onBattery) { warned = 101; return; }
        const level = levels.filter(l => percent <= l && l < warned).pop();
        if (level === undefined) return;
        warned = level;
        const critical = level === levels[levels.length - 1];
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-i", critical ? "lucide:battery-warning" : "lucide:battery-low",
            "-u", critical ? "critical" : "normal",
            critical ? "Battery almost empty" : "Battery low",
            `${percent}% left, plug in the charger`]);
    }
    onPercentChanged: check()
    Connections {
        target: UPower
        function onOnBatteryChanged() { root.check(); }
    }
}
