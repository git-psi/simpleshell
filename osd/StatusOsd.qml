// Status OSD: volume, brightness, keyboard backlight (bar); mic, power profile, airplane mode,
// touchpad, charger (icon + label). It follows the values themselves, not the keys: it also shows
// when the kernel handles the key on its own (asus-wmi: profile, keyboard; rfkill: airplane mode)
// or when the setting changes elsewhere.
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import ".."
import "../components"
import "../services"
import "../Format.js" as Format

Osd {
    id: osd
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false

    property string icon: ""
    property real level: -1     // 0..1; -1 = no bar, just the label
    property string label: ""
    property bool off: false    // gray: muted, off

    kind: "status"
    cardWidth: level >= 0 ? Theme.osdWidth : message.implicitWidth + Theme.rowPad * 2

    function showLevel(icon, value, off) {
        osd.icon = icon; level = value; label = ""; osd.off = off; timeout = Theme.osdTimeout;
        show();
    }
    function showLabel(icon, text, off) {
        osd.icon = icon; level = -1; label = text; osd.off = off; timeout = Theme.osdLabelTimeout;
        show();
    }

    PwObjectTracker { objects: [osd.sink, osd.source] }
    onVolumeChanged: showLevel(Format.volumeIcon(volume, muted), volume, muted)
    onMutedChanged: showLevel(Format.volumeIcon(volume, muted), volume, muted)
    onMicMutedChanged: showLabel(micMuted ? "mic-off" : "mic", micMuted ? "Microphone muted" : "Microphone on", micMuted)

    Connections {
        target: Brightness
        function onValueChanged() { osd.showLevel("sun", Brightness.value, false); }
    }

    Connections {
        target: Energy
        function onProfileChanged() {
            const p = Format.profile(Energy.profile, PowerProfile);
            osd.showLabel(p.icon, p.name, false);
        }
    }

    // Charger plugged in or unplugged, with the battery level.
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            const level = Format.percent(UPower.displayDevice) + "%";
            osd.showLabel(UPower.onBattery ? "unplug" : "battery-charging",
                          (UPower.onBattery ? "Unplugged - " : "Plugged in - ") + level, false);
        }
    }

    Connections {
        target: Ui
        function onTouchpadChanged() {
            osd.showLabel(Ui.touchpad ? "touchpad" : "touchpad-off",
                          Ui.touchpad ? "Touchpad on" : "Touchpad off", !Ui.touchpad);
        }
    }

    // Keyboard backlight: sysfs doesn't notify changes, so the file is polled.
    property int kbd: -1
    property int kbdMax: 0
    FileView {
        id: kbdMaxFile
        path: Config.kbdLed !== "" ? "/sys/class/leds/" + Config.kbdLed + "/max_brightness" : ""
        onLoaded: osd.kbdMax = parseInt(text()) || 0
    }
    FileView {
        id: kbdFile
        path: Config.kbdLed !== "" ? "/sys/class/leds/" + Config.kbdLed + "/brightness" : ""
        onLoaded: {
            const v = parseInt(text());
            if (isNaN(v) || v === osd.kbd) return;
            const first = osd.kbd < 0;
            osd.kbd = v;
            if (!first && osd.kbdMax > 0) osd.showLevel(v === 0 ? "keyboard-off" : "keyboard", v / osd.kbdMax, v === 0);
        }
    }
    Timer { interval: 250; running: osd.kbdMax > 0; repeat: true; onTriggered: kbdFile.reload() }

    // Airplane mode = all radios blocked. `rfkill event` gives the state of each one at startup,
    // then every change: "… idx 1 type 1 op 2 soft 1 hard 0".
    property var radios: ({})
    property bool airplane: false
    onAirplaneChanged: showLabel("plane", airplane ? "Airplane mode on" : "Airplane mode off", !airplane)
    Process {
        running: true
        command: ["rfkill", "event"]
        stdout: SplitParser {
            onRead: (line) => {
                const m = line.match(/idx (\d+) type \d+ op (\d+) soft (\d) hard (\d)/);
                if (!m) return;
                const radios = Object.assign({}, osd.radios);
                if (m[2] === "1") delete radios[m[1]];   // op 1: radio removed
                else radios[m[1]] = m[3] === "1" || m[4] === "1";
                osd.radios = radios;
                const states = Object.values(radios);
                osd.airplane = states.length > 0 && states.every(b => b);
            }
        }
    }

    Icon {
        id: glyph
        visible: osd.level >= 0
        anchors { left: parent.left; leftMargin: Theme.rowPad; verticalCenter: parent.verticalCenter }
        name: osd.icon
        color: osd.off ? Theme.textDim : Theme.text
    }
    Bar {
        visible: osd.level >= 0
        anchors {
            left: glyph.right; leftMargin: Theme.iconGap
            right: value.left; rightMargin: Theme.iconGap
            verticalCenter: parent.verticalCenter
        }
        value: osd.level
        muted: osd.off
        animated: true
    }
    Txt {
        id: value
        visible: osd.level >= 0
        anchors { right: parent.right; rightMargin: Theme.rowPad; verticalCenter: parent.verticalCenter }
        width: Theme.controlTiny
        horizontalAlignment: Text.AlignRight
        text: Math.round(osd.level * 100)
        font.weight: Font.Bold
        font.features: ({ "tnum": 1 })
    }
    Row {
        id: message
        visible: osd.level < 0
        anchors.centerIn: parent
        spacing: Theme.iconGap
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: osd.icon
            color: osd.off ? Theme.textDim : Theme.text
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: osd.label
            font.weight: Font.Bold
        }
    }
}
