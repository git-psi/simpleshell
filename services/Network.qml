pragma Singleton
// Wi-Fi through NetworkManager (Quickshell.Networking module, directly over D-Bus): state, visible
// networks, connecting. nmcli is only used for saved networks out of range, which the module
// doesn't provide.
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQml
import QtQuick
import ".."

Singleton {
    id: root
    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool available: device !== null
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool blocked: !Networking.wifiHardwareEnabled

    // Visible networks (one per name, hidden networks without a name are skipped).
    readonly property var all: wifiOn ? (device?.networks.values ?? []).filter(n => n.name !== "") : []
    readonly property var active: all.find(n => n.connected) ?? null
    readonly property string ssid: active?.name ?? ""
    readonly property bool connected: active !== null
    readonly property bool online: Networking.connectivity === NetworkConnectivity.Full
        || Networking.connectivity === NetworkConnectivity.Unknown
    // The others, saved ones first, then strongest to weakest.
    readonly property var networks: all.filter(n => !n.connected)
        .sort((a, b) => (b.known - a.known) || (b.signalStrength - a.signalStrength))
    readonly property string connecting: all.find(n => n.state === ConnectionState.Connecting)?.name ?? ""

    property var savedAway: []      // saved networks out of range: names only

    property string error: ""       // last failure, shown under the network
    property string errorFor: ""
    property string withPassword: "" // network a password was just given for

    // Wi-Fi page open: continuous scanning.
    property bool detailed: false

    function toggle() { if (!blocked) Networking.wifiEnabled = !Networking.wifiEnabled; }
    function secure(n) { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe; }
    // Enterprise networks (username + password): set up in nm-connection-editor.
    function enterprise(n) {
        return [WifiSecurityType.Wpa2Eap, WifiSecurityType.WpaEap, WifiSecurityType.Wpa3SuiteB192,
                WifiSecurityType.Leap, WifiSecurityType.DynamicWep].includes(n.security);
    }
    // Without a password: open or already saved network.
    function connect(n, password) {
        error = "";
        withPassword = password ? n.name : "";
        if (password) n.connectWithPsk(password);
        else n.connect();
    }
    function forgetSaved(name) {
        Quickshell.execDetached(["nmcli", "connection", "delete", "id", name]);
        savedAway = savedAway.filter(s => s !== name);
    }
    function openSettings() { Quickshell.execDetached(["nm-connection-editor"]); }

    function level(strength) { return strength >= 0.75 ? 4 : strength >= 0.5 ? 3 : strength >= 0.25 ? 2 : 1; }

    function failed(n, reason) {
        errorFor = n.name;
        error = reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout
            ? "Wrong password"
            : reason === ConnectionFailReason.WifiNetworkLost ? "Network out of range"
            : "Couldn't connect";
        // A rejected password must not stay saved: forget the profile that was created.
        if (withPassword === n.name && error === "Wrong password") n.forget();
        withPassword = "";
    }

    Binding {
        when: root.device !== null
        target: root.device
        property: "scannerEnabled"
        value: root.detailed && Ui.panelOpen && root.wifiOn
    }

    Instantiator {
        model: root.device?.networks ?? null
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectionFailed(reason) { root.failed(modelData, reason); }
        }
    }

    onSsidChanged: if (connected) { error = ""; withPassword = ""; }
    onDetailedChanged: if (detailed) saved.running = true
    onAllChanged: if (detailed && !saved.running) saved.running = true

    // nmcli -t separates with ":" and escapes those in values as "\:".
    function fields(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) { cur += line[++i]; continue; }
            if (line[i] === ":") { out.push(cur); cur = ""; continue; }
            cur += line[i];
        }
        out.push(cur);
        return out;
    }

    Process {
        id: saved
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const visible = root.all.map(n => n.name);
                root.savedAway = text.split("\n").map(root.fields)
                    .filter(f => f[1] === "802-11-wireless" && !visible.includes(f[0]))
                    .map(f => f[0]);
            }
        }
    }
}
