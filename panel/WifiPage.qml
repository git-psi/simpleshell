// Wi-Fi page of the panel: connected network, available networks (password typed in place), saved
// networks out of range, advanced settings. Same rows as the Bluetooth page.
import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"

ColumnLayout {
    id: root
    spacing: Theme.section
    property string openName: ""    // expanded network (options or password)
    readonly property bool usable: Network.available && Network.wifiOn

    Component.onCompleted: Network.detailed = true
    Component.onDestruction: Network.detailed = false

    function icon(n) { return ["wifi-zero", "wifi-zero", "wifi-low", "wifi-high", "wifi"][Network.level(n.signalStrength)]; }
    // Open or saved: connect directly. Secured: expand the password field first.
    function connect(n) {
        if (n.known || !Network.secure(n)) { openName = ""; Network.connect(n, ""); }
        else if (Network.enterprise(n)) { Ui.panelOpen = false; Network.openSettings(); }
        else openName = n.name;
    }
    function submit(n, password) {
        if (password === "") return;
        Network.connect(n, password);
        openName = "";
    }

    PageHeader {
        Layout.fillWidth: true
        title: "Wi-Fi"
        checked: Network.wifiOn
        onToggled: Network.toggle()
    }

    Txt {
        visible: !root.usable
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: !Network.available ? "No Wi-Fi adapter."
            : Network.blocked ? "Wi-Fi is blocked by the computer's switch."
            : "Wi-Fi is off."
        color: Theme.textDim
    }
    // Keeps the header at the top when the lists are hidden.
    Item { visible: !root.usable; Layout.fillHeight: true }

    Flickable {
        visible: root.usable
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
                count: Network.connected ? 1 : 0
                Repeater {
                    model: Network.active ? [Network.active] : []
                    delegate: NetworkRow {}
                }
            }
            ListSection {
                title: "Available"
                count: Network.networks.length
                empty: "No networks"
                showAlways: true
                Repeater {
                    model: ScriptModel { values: Network.networks }
                    delegate: NetworkRow {}
                }
            }
            ListSection {
                title: "Saved, out of range"
                count: Network.savedAway.length
                Repeater {
                    model: Network.savedAway
                    delegate: ListRow {
                        required property string modelData
                        required property int index
                        first: index === 0
                        icon: "wifi-off"
                        title: modelData
                        actionText: "Forget"
                        actionDanger: true
                        onActionClicked: Network.forgetSaved(modelData)
                    }
                }
            }
            ListCard {
                Layout.fillWidth: true
                count: 1
                ListRow {
                    first: true
                    icon: "settings"
                    title: "Advanced settings"
                    chevron: true
                    onClicked: { Ui.panelOpen = false; Network.openSettings(); }
                }
            }
        }
    }

    // A visible network. Saved: clicking expands "Forget". Secured and unknown: "Connect" expands
    // the password field.
    component NetworkRow: ListRow {
        id: row
        required property var modelData
        required property int index
        readonly property var net: modelData
        readonly property bool busy: Network.connecting === net.name
        readonly property bool asking: open && !net.known && Network.secure(net)

        first: index === 0
        icon: root.icon(net)
        active: net.connected
        title: net.name
        failed: !busy && Network.errorFor === net.name && Network.error !== ""
        sub: busy ? "Connecting…"
            : failed ? Network.error
            : net.connected && !Network.online ? "No internet"
            : ""
        expandable: net.known
        open: root.openName === net.name
        onClicked: root.openName = open ? "" : net.name
        actionText: busy || asking ? "" : net.connected ? "Disconnect" : "Connect"
        actionPrimary: !net.connected && !net.known
        actionEnabled: Network.connecting === ""
        onActionClicked: net.connected ? net.disconnect() : root.connect(net)

        // Password
        Column {
            visible: row.asking
            width: parent.width
            padding: Theme.iconGap
            topPadding: 0
            spacing: Theme.cardPad
            onVisibleChanged: if (visible) { pass.text = ""; pass.forceActiveFocus(); }

            Rectangle {
                width: parent.width - parent.padding * 2
                height: Theme.control
                radius: Theme.radiusSmall
                color: Theme.sunken
                TextInput {
                    id: pass
                    anchors {
                        left: parent.left; leftMargin: Theme.iconGap
                        right: eye.left; rightMargin: Theme.gap
                        verticalCenter: parent.verticalCenter
                    }
                    echoMode: eye.shown ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentInk
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    clip: true
                    onAccepted: root.submit(row.net, text)
                    Keys.onEscapePressed: root.openName = ""
                    Txt {
                        visible: pass.text === ""
                        text: "Password"
                        color: Theme.textDim
                    }
                }
                IconButton {
                    id: eye
                    property bool shown: false
                    anchors { right: parent.right; rightMargin: Theme.inset; verticalCenter: parent.verticalCenter }
                    size: Theme.controlSmall
                    radius: Theme.inner(Theme.radiusSmall, Theme.inset)
                    flat: true
                    icon: shown ? "eye-off" : "eye"
                    onClicked: shown = !shown
                }
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: parent.padding
                spacing: Theme.gap
                TextButton { text: "Cancel"; onClicked: root.openName = "" }
                TextButton {
                    text: "Connect"
                    primary: true
                    onClicked: root.submit(row.net, pass.text)
                }
            }
        }

        InfoRow {
            visible: row.net.known
            text: row.net.connected ? "Reconnects automatically" : "Saved on this computer"
            onClicked: { root.openName = ""; row.net.forget(); }
        }
    }
}
