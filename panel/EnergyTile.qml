// Power profile: Balanced (neutral) → Power saver → Performance.
import Quickshell.Services.UPower
import QtQuick
import "../components"
import "../services"
import "../Format.js" as Format

Tile {
    readonly property int profile: Energy.profile

    icon: Format.profile(profile, PowerProfile).icon
    label: "Power"
    sub: Format.profile(profile, PowerProfile).name
    active: profile !== PowerProfile.Balanced

    onClicked: {
        if (profile === PowerProfile.Balanced)
            Energy.set(PowerProfile.PowerSaver);
        else if (profile === PowerProfile.PowerSaver && PowerProfiles.hasPerformanceProfile)
            Energy.set(PowerProfile.Performance);
        else
            Energy.set(PowerProfile.Balanced);
    }
}
