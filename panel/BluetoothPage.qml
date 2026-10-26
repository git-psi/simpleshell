// Bluetooth page of the panel: connected, paired and nearby devices (discovery runs while the page
// is open). Same sections and rows as the Wi-Fi page.
import Quickshell.Bluetooth
import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"
import "../Format.js" as Format

ColumnLayout {
    id: root
    spacing: Theme.section

    property string openAddress: ""   // device whose options are expanded
    readonly property var connected: Bt.devices.filter(d => d.connected)
    readonly property var paired: Bt.devices.filter(d => d.paired && !d.connected)
    // Nearby devices: those with a name (the others are mostly anonymous smart objects; they show
    // up as soon as their name arrives).
    readonly property var nearby: Bt.devices.filter(d => !d.paired && !d.connected && d.deviceName !== "")

    Component.onCompleted: Bt.searching = true
    Component.onDestruction: Bt.searching = false

    // Lucide icon from the BlueZ icon (audio-headset, input-mouse…).
    readonly property var kinds: [
        { match: /headset|headphone/, icon: "headphones" },
        { match: /keyboard/,          icon: "keyboard" },
        { match: /mouse|tablet/,      icon: "mouse" },
        { match: /gaming|joystick/,   icon: "gamepad-2" },
        { match: /phone/,             icon: "smartphone" },
        { match: /audio|speaker/,     icon: "speaker" },
        { match: /computer/,          icon: "laptop" }
    ]
    function icon(d) {
        return kinds.find(k => k.match.test(d.icon ?? ""))?.icon ?? "bluetooth";
    }

    PageHeader {
        Layout.fillWidth: true
        title: "Bluetooth"
        checked: Bt.on
        onToggled: Bt.toggle()
    }

    Txt {
        visible: !Bt.on
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: !Bt.available ? "No Bluetooth adapter."
            : Bt.blocked ? "Bluetooth is blocked. The switch unblocks it."
            : "Bluetooth is off."
        color: Theme.textDim
    }
    // Keeps the header at the top when the lists are hidden.
    Item { visible: !Bt.on; Layout.fillHeight: true }

    // Pairing code requested by a device.
    Rectangle {
        id: ask
        visible: Bt.on && Bt.request !== null
        Layout.fillWidth: true
        implicitHeight: request.implicitHeight + Theme.cardPad * 2
        radius: Theme.radius
        color: Theme.surface

        readonly property bool confirm: Bt.request?.type === "confirm"
        readonly property string code: Bt.request?.passkey ?? ""
        readonly property string device: Bt.request?.name || "the device"

        Column {
            id: request
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.cardPad }
            spacing: Theme.cardPad
            TwoLines {
                width: parent.width
                leftPadding: Theme.inset
                title: "Pair \"" + ask.device + "\""
                sub: !ask.confirm ? "Type this code on the device, then Enter"
                    : ask.code !== "" ? "Check that the device shows the same code"
                    : "The device asks to pair"
                strong: true
            }
            Txt {
                visible: ask.code !== ""
                leftPadding: Theme.inset
                text: ask.code.replace(/(\d{3})(\d{3})/, "$1 $2")
                font.pixelSize: Theme.fontTitle
                font.weight: Font.Bold
                font.features: ({ "tnum": 1 })
            }
            Row {
                anchors.right: parent.right
                spacing: Theme.gap
                TextButton {
                    text: ask.confirm ? "Decline" : "Cancel"
                    onClicked: {
                        if (ask.confirm) { Bt.answer(false); return; }
                        Bt.devices.find(d => d.address === Bt.request.address)?.cancelPair();
                        Bt.request = null;
                    }
                }
                TextButton {
                    visible: ask.confirm
                    text: "Accept"
                    primary: true
                    onClicked: Bt.answer(true)
                }
            }
        }
    }

    Flickable {
        visible: Bt.on
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: body
            width: parent.width
            spacing: Theme.section

            ListSection {
                title: "Connected"
                count: root.connected.length
                Repeater {
                    model: ScriptModel { values: root.connected }
                    delegate: DeviceRow {}
                }
            }
            ListSection {
                title: "Paired"
                count: root.paired.length
                Repeater {
                    model: ScriptModel { values: root.paired }
                    delegate: DeviceRow {}
                }
            }
            ListSection {
                title: "Nearby"
                count: root.nearby.length
                empty: "No devices"
                showAlways: true
                Repeater {
                    model: ScriptModel { values: root.nearby }
                    delegate: DeviceRow {}
                }
            }
        }
    }

    // A device. Paired: clicking expands its options. The button does the current action
    // (pair, connect, disconnect, cancel).
    component DeviceRow: ListRow {
        id: row
        required property var modelData
        required property int index
        readonly property var dev: modelData
        readonly property bool busy: dev.state === BluetoothDeviceState.Connecting
            || dev.state === BluetoothDeviceState.Disconnecting
        property string failure: ""   // last failure, cleared on the next attempt
        property bool wasConnecting: false

        first: index === 0
        icon: root.icon(dev)
        active: dev.connected
        title: Format.btName(dev)
        failed: !busy && !dev.pairing && failure !== ""
        sub: dev.pairing ? "Pairing…"
            : dev.state === BluetoothDeviceState.Connecting ? "Connecting…"
            : dev.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
            : dev.blocked ? "Blocked"
            : failure
        expandable: dev.paired
        open: root.openAddress === dev.address
        onClicked: root.openAddress = open ? "" : dev.address
        actionText: dev.blocked ? ""
            : dev.pairing ? "Cancel"
            : dev.connected ? "Disconnect"
            : dev.paired ? "Connect" : "Pair"
        actionPrimary: !dev.paired && !dev.pairing
        actionEnabled: !busy
        onActionClicked: {
            failure = "";
            if (dev.pairing) dev.cancelPair();
            else if (dev.connected) dev.disconnect();
            else if (dev.paired) dev.connect();
            else Bt.pair(dev);
        }

        // Options: auto-connect (trusted device), wake-up, block, forget.
        OptionRow {
            text: "Connect automatically"
            checked: row.dev.trusted
            onToggled: row.dev.trusted = !row.dev.trusted
        }
        OptionRow {
            text: "Can wake the computer"
            checked: row.dev.wakeAllowed
            onToggled: row.dev.wakeAllowed = !row.dev.wakeAllowed
        }
        OptionRow {
            text: "Block"
            checked: row.dev.blocked
            onToggled: row.dev.blocked = !row.dev.blocked
        }
        InfoRow {
            text: row.dev.address
            onClicked: { root.openAddress = ""; row.dev.forget(); }
        }

        // Once paired, connect right away. BlueZ doesn't say why an attempt fails: it's deduced
        // from the return to the previous state.
        Connections {
            target: row.dev
            function onPairedChanged() { if (row.dev.paired && !row.dev.connected) row.dev.connect(); }
            function onPairingChanged() {
                if (row.dev.pairing) return;
                if (Bt.request?.address === row.dev.address) Bt.request = null;
                if (!row.dev.paired) row.failure = "Pairing failed";
            }
            function onStateChanged() {
                if (row.dev.state === BluetoothDeviceState.Connecting) row.wasConnecting = true;
                else if (row.wasConnecting) {
                    row.wasConnecting = false;
                    row.failure = row.dev.connected ? "" : "Couldn't connect";
                }
            }
        }
    }
}
