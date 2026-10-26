pragma Singleton
// Power profile. Fn+F5 changes it in the kernel (asus-wmi) and power-profiles-daemon only notices
// late: so platform_profile is read directly (sysfs doesn't notify, the file is polled). Without
// that file (other machines), power-profiles-daemon is followed.
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root
    property string platform: ""
    property int profile: PowerProfiles.profile

    function set(p) {
        root.profile = p;   // right away, without waiting for the echo
        PowerProfiles.profile = p;
    }

    FileView {
        id: file
        path: "/sys/firmware/acpi/platform_profile"
        onLoaded: {
            const v = text().trim();
            if (v === root.platform) return;
            root.platform = v;
            root.profile = v === "quiet" || v === "low-power" ? PowerProfile.PowerSaver
                         : v === "performance" ? PowerProfile.Performance : PowerProfile.Balanced;
        }
    }
    Timer { interval: 250; running: root.platform !== ""; repeat: true; onTriggered: file.reload() }
    Connections {
        target: PowerProfiles
        enabled: root.platform === ""
        function onProfileChanged() { root.profile = PowerProfiles.profile; }
    }
}
