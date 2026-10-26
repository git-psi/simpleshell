// What the "Night light" and "Caffeine" tiles actually do.
// Setting `running` to false stops the program.
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    // New temperature picked: hyprsunset is restarted (it can't change it while running).
    Process {
        id: night
        running: Ui.nightLight && !restart.running
        command: ["hyprsunset", "-t", String(Settings.nightTemperature)]
    }
    Connections {
        target: Settings
        function onNightTemperatureChanged() { if (night.running) restart.restart(); }
    }
    Timer { id: restart; interval: 300 }
    Process {
        running: Ui.caffeine
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=simpleshell", "--why=Caffeine", "sleep", "infinity"]
    }
}
