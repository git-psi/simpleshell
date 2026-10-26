pragma Singleton
// Sound through PipeWire: outputs and inputs (to pick one), apps playing sound (volume of each),
// and readable names instead of sound card names.
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import ".."

Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var sinks: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => !n.isSink && !n.isStream)
    // Apps sending sound (playback streams).
    readonly property var apps: nodes.filter(n => n.isSink && n.isStream)

    function setDefault(node) {
        if (node.isSink) Pipewire.preferredDefaultAudioSink = node;
        else Pipewire.preferredDefaultAudioSource = node;
    }
    function setVolume(node, v) {
        if (!node?.audio) return;
        node.audio.muted = false;
        node.audio.volume = v;
    }
    function toggleMute(node) { if (node?.audio) node.audio.muted = !node.audio.muted; }

    // Connection type: "Bluetooth", "USB", "HDMI" or "Built-in".
    function kind(n) {
        const p = n.properties ?? {};
        if (p["device.api"] === "bluez5") return "Bluetooth";
        if (p["device.bus"] === "usb" || /usb/i.test(n.name)) return "USB";
        if (/hdmi|displayport/i.test(n.name + n.description)) return "HDMI";
        return "Built-in";
    }
    // Displayed name: the device's own if it has a real one (headset, USB mic), otherwise its role.
    function label(n) {
        const k = kind(n);
        if (k === "HDMI") return "Display (HDMI)";
        if (k === "Built-in") return n.isSink ? "Speakers" : "Built-in microphone";
        return n.nickname || n.description || n.name;
    }
    function appName(n) {
        const p = n.properties ?? {};
        return p["application.name"] || n.description || n.name;
    }

    // A node's properties and volume are only up to date while it is tracked.
    PwObjectTracker { objects: Pipewire.nodes.values }
}
