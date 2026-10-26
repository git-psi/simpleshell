// Shared formatting (volume icon, Bluetooth name, battery, durations, power profile).
.pragma library

function volumeIcon(volume, muted) {
    return muted || volume === 0 ? "volume-x" : volume < 0.5 ? "volume-1" : "volume-2";
}

// Bluetooth device: always "Name - 72%".
function btName(d) {
    const name = d.deviceName !== "" ? d.deviceName : "Unknown device";
    return d.batteryAvailable ? name + " - " + Math.round(d.battery * 100) + "%" : name;
}

// UPower battery level as a whole %: depending on the version it comes as 0..1 or 0..100.
function percent(device) {
    const p = device?.percentage ?? 0;
    return Math.round(p <= 1 ? p * 100 : p);
}

function time(s) {
    s = Math.max(0, Math.floor(s || 0));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
}

// Power profile (PowerProfiles): icon and name. `PowerProfile` = the Quickshell enum.
function profile(p, PowerProfile) {
    return p === PowerProfile.PowerSaver ? { icon: "leaf", name: "Power saver" }
        : p === PowerProfile.Performance ? { icon: "zap", name: "Performance" }
        : { icon: "gauge", name: "Balanced" };
}
