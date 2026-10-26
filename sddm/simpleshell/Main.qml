// SDDM login screen in the simpleshell style: user and password in the middle, session and
// sleep / restart / shut down buttons at the bottom. After 10 s idle, everything fades out and
// leaves a big clock. The values copy Theme.qml (dark theme); SDDM can't read the shell.
import QtQuick
import SddmComponents 2.0

Rectangle {
    id: root

    // Values from Theme.qml
    readonly property color bg: "#161616"
    readonly property color surface: "#232323"
    readonly property color surfaceHi: "#2e2e2e"
    readonly property color text: "#f2f2f2"
    readonly property color textDim: "#8e8e8e"
    readonly property color danger: "#e5534b"
    readonly property color outline: surfaceHi
    readonly property color accent: config.accent || "#4fa3e6"
    readonly property string font: "Ubuntu"
    readonly property int fontTitle: 20
    readonly property int fontLarge: 14
    readonly property int fontBody: 13
    readonly property int fontSmall: 11
    readonly property int fontClock: 160   // clock of the idle screen
    readonly property real clockOpacity: 0.5
    // White barely tinted with the wallpaper's average color (theme.conf, neutral otherwise).
    readonly property color tint: config.tint || "#808080"
    readonly property color clockInk: Qt.hsla(tint.hslHue, Math.min(tint.hslSaturation, 0.35), 0.9, 1)
    readonly property int control: 40
    readonly property int tile: 56
    readonly property int radiusLarge: 18
    readonly property int radius: 14
    readonly property int radiusControl: 10
    readonly property int radiusSmall: 8
    readonly property int panelPad: 20
    readonly property int gap: 8
    readonly property int iconGap: 12
    readonly property int inset: 4
    readonly property real disabledOpacity: 0.4
    readonly property int cardPad: 10
    readonly property int rowPad: 16
    readonly property int fieldWidth: 280
    readonly property int idleDelay: 10000
    readonly property int fade: 600         // going idle
    readonly property int fadeBack: 120     // back to login: almost instant

    // Like the shell's floating elements (menus, OSD…): solid background and 1 px outline, setting
    // them apart from the wallpaper.
    component Card: Rectangle {
        color: root.bg
        radius: root.radius
        border.width: 1
        border.color: root.outline
    }

    // User and session: the last ones used.
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    readonly property string userName: userModel.data(userModel.index(userIndex, 0), Qt.UserRole + 1) ?? ""
    readonly property string realName: userModel.data(userModel.index(userIndex, 0), Qt.UserRole + 2) || userName
    readonly property string sessionName: sessionModel.data(sessionModel.index(sessionIndex, 0), Qt.UserRole + 4) ?? ""
    property string error: ""
    property bool idle: false

    // Mouse moving or key pressed: come back from the idle screen.
    function wake() {
        idle = false;
        idleTimer.restart();
    }

    function switchUser(step) {
        const n = userModel.rowCount();
        userIndex = (userIndex + step + n) % n;
        pass.text = "";
        error = "";
        pass.forceActiveFocus();
    }

    function login() {
        if (pass.text === "") return;
        error = "";
        sddm.login(userName, pass.text, sessionIndex);
    }

    color: bg

    Connections {
        target: sddm
        function onLoginFailed() {
            root.error = "Wrong password";
            pass.text = "";
            pass.forceActiveFocus();
        }
    }

    Image {
        anchors.fill: parent
        visible: (config.background ?? "") !== ""
        source: visible ? config.background : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // Everything that fades out when idle
    Item {
        anchors.fill: parent
        // Stays visible even when transparent: the field keeps keyboard focus for waking up.
        opacity: root.idle ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: root.idle ? root.fade : root.fadeBack; easing.type: Easing.InOutQuad } }

        // User and password
        Card {
            anchors.centerIn: parent
            width: login.implicitWidth + root.panelPad * 2
            height: login.implicitHeight + root.panelPad * 2
            radius: root.radiusLarge
            Column {
                id: login
                anchors.centerIn: parent
                spacing: root.iconGap

                // Avatar, with controls on both sides to switch to the previous / next user when
                // there are several.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.iconGap
                    Repeater {
                        model: [-1, 0, 1]
                        Loader {
                            required property int modelData
                            anchors.verticalCenter: parent.verticalCenter
                            sourceComponent: modelData === 0 ? avatar : switcher
                            active: modelData === 0 || userModel.rowCount() > 1
                            visible: active
                            property int step: modelData
                        }
                    }
                }
                Component {
                    id: avatar
                    Rectangle {
                        width: root.tile
                        height: root.tile
                        radius: root.radiusControl
                        color: root.surfaceHi
                        Text {
                            anchors.centerIn: parent
                            text: root.realName.charAt(0).toUpperCase()
                            color: root.text
                            font { family: root.font; pixelSize: root.fontTitle; weight: Font.Bold }
                        }
                    }
                }
                Component {
                    id: switcher
                    Rectangle {
                        width: root.control - root.inset * 2
                        height: width
                        radius: root.radiusSmall - root.inset
                        color: switchMouse.containsMouse ? root.surfaceHi : "transparent"
                        Image {
                            anchors.centerIn: parent
                            source: parent.parent.step < 0 ? "icons/chevron-left.svg" : "icons/chevron-right.svg"
                            sourceSize: Qt.size(16, 16)
                        }
                        MouseArea {
                            id: switchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.switchUser(parent.parent.step)
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.realName
                    color: root.text
                    font { family: root.font; pixelSize: root.fontLarge; weight: Font.Bold }
                }
                Item { width: 1; height: root.inset }

                Rectangle {
                    width: root.fieldWidth
                    height: root.control
                    radius: root.radiusSmall
                    color: root.surface
                    border.width: pass.activeFocus ? 1 : 0
                    border.color: root.accent

                    TextInput {
                        id: pass
                        anchors {
                            left: parent.left; leftMargin: root.iconGap
                            right: submit.left; rightMargin: root.gap
                            verticalCenter: parent.verticalCenter
                        }
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: root.text
                        selectionColor: root.accent
                        cursorDelegate: Rectangle { width: 2; color: root.accent }
                        font { family: root.font; pixelSize: root.fontBody }
                        clip: true
                        focus: true
                        onTextChanged: root.error = ""
                        // A key pressed while idle wakes the screen; it's still typed.
                        Keys.onPressed: event => { root.wake(); event.accepted = false; }
                        onAccepted: root.login()
                        Text {
                            visible: pass.text === ""
                            text: "Password"
                            color: root.textDim
                            font: pass.font
                        }
                    }
                    Rectangle {
                        id: submit
                        anchors { right: parent.right; rightMargin: root.inset; verticalCenter: parent.verticalCenter }
                        width: root.control - root.inset * 2
                        height: width
                        radius: root.radiusSmall - root.inset
                        color: submitMouse.containsMouse ? root.surfaceHi : "transparent"
                        Image {
                            anchors.centerIn: parent
                            source: "icons/arrow-right.svg"
                            sourceSize: Qt.size(16, 16)
                        }
                        MouseArea {
                            id: submitMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.login()
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: root.fontSmall * 2
                    text: root.error !== "" ? root.error : keyboard.capsLock ? "Caps Lock is on" : ""
                    color: root.error !== "" ? root.danger : root.textDim
                    font { family: root.font; pixelSize: root.fontSmall }
                }
            }
        }

        // Session (click to switch to the next one)
        Card {
            x: root.panelPad * 2
            anchors { bottom: parent.bottom; bottomMargin: root.panelPad * 2 }
            width: session.implicitWidth + root.rowPad * 2
            height: root.control
            radius: root.radiusControl
            Text {
                id: session
                anchors.centerIn: parent
                text: root.sessionName
                color: root.textDim
                font { family: root.font; pixelSize: root.fontBody }
                MouseArea {
                    anchors.fill: parent
                    enabled: sessionModel.rowCount() > 1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                }
            }
        }

        // Sleep, restart, shut down
        Row {
            anchors { right: parent.right; bottom: parent.bottom; margins: root.panelPad * 2 }
            spacing: root.gap
            Repeater {
                model: [
                    { icon: "moon", action: () => sddm.suspend(), on: sddm.canSuspend },
                    { icon: "rotate-cw", action: () => sddm.reboot(), on: sddm.canReboot },
                    { icon: "power", action: () => sddm.powerOff(), on: sddm.canPowerOff }
                ]
                // Always shown, grayed out when SDDM says the action isn't possible (all of them in
                // test mode).
                Card {
                    required property var modelData
                    opacity: modelData.on ? 1 : root.disabledOpacity
                    width: root.control
                    height: root.control
                    radius: root.radiusControl
                    color: mouse.containsMouse ? root.surfaceHi : root.bg
                    Image {
                        anchors.centerIn: parent
                        source: "icons/" + parent.modelData.icon + ".svg"
                        sourceSize: Qt.size(18, 18)
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        enabled: parent.modelData.on
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.modelData.action()
                    }
                }
            }
        }
    }

    // Big clock when idle: slightly transparent, tinted with the wallpaper's average color
    // (computed by install.sh) to blend in.
    Item {
        id: clock
        property date now: new Date()
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.height / 8
        width: time.implicitWidth
        height: time.implicitHeight
        opacity: root.idle ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.idle ? root.fade : root.fadeBack; easing.type: Easing.InOutQuad } }

        Text {
            id: time
            text: Qt.formatTime(clock.now, "HH:mm")
            color: root.clockInk
            style: Text.Outline   // thin dark outline, setting the clock apart from the background
            styleColor: root.bg
            opacity: root.clockOpacity
            font {
                family: "Open Sans"   // clock font (ttf-opensans package)
                pixelSize: root.fontClock
                weight: Font.ExtraBold
            }
        }
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.now = new Date()
        }
    }

    Timer {
        id: idleTimer
        interval: root.idleDelay
        running: true
        onTriggered: root.idle = true
    }
    // On top of everything but click-through: only watches the mouse go by.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onPositionChanged: root.wake()
    }

    Component.onCompleted: pass.forceActiveFocus()
}
