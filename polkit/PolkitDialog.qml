// Administrator rights request (polkit agent): what is requested, and the password.
// Escape or "Cancel" denies; Enter or "Authorize" sends the password.
// A click outside doesn't close the window: it's a request that needs an answer.
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import QtQuick
import ".."
import "../components"

Scope {
    id: root

    PolkitAgent {
        id: agent
        onAuthenticationRequestStarted: Ui.closeAll()
    }

    PanelWindow {
        id: win
        readonly property var flow: agent.flow
        readonly property bool open: agent.isActive && flow !== null

        screen: Ui.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: open

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "simpleshell-polkit"
        WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        function submit() {
            if (!flow || !flow.isResponseRequired) return;
            flow.submit(pass.text);
            pass.text = "";
        }
        function cancel() { if (flow) flow.cancelAuthenticationRequest(); }

        onOpenChanged: if (open) { pass.text = ""; pass.forceActiveFocus(); }

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim
            MouseArea { anchors.fill: parent }
        }

        Rectangle {
            id: box
            anchors.centerIn: parent
            width: Theme.dialogWidth
            height: content.implicitHeight + Theme.panelPad * 2
            radius: Theme.radiusLarge
            color: Theme.bg
            border.width: 1
            border.color: Theme.outline

            Column {
                id: content
                x: Theme.panelPad
                y: Theme.panelPad
                width: parent.width - Theme.panelPad * 2
                spacing: Theme.section

                Column {
                    width: parent.width
                    spacing: Theme.inset
                    Txt {
                        text: "Authentication required"
                        font.pixelSize: Theme.fontLarge
                        font.weight: Font.Bold
                    }
                    Txt {
                        width: parent.width
                        text: win.flow?.message ?? ""
                        color: Theme.textDim
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.gap
                    Rectangle {
                        width: parent.width
                        height: Theme.control
                        radius: Theme.radiusSmall
                        color: Theme.surface
                        TextInput {
                            id: pass
                            anchors {
                                left: parent.left; right: parent.right; margins: Theme.iconGap
                                verticalCenter: parent.verticalCenter
                            }
                            enabled: win.flow?.isResponseRequired ?? false
                            echoMode: (win.flow?.responseVisible ?? false) ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "•"
                            color: Theme.text
                            cursorDelegate: Rectangle { width: Theme.tight; color: Theme.accent }
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentInk
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody
                            clip: true
                            focus: win.open
                            onAccepted: win.submit()
                            Keys.onEscapePressed: win.cancel()
                            Txt {
                                visible: pass.text === ""
                                text: "Password"
                                color: Theme.textDim
                            }
                        }
                    }
                    Txt {
                        visible: text !== ""
                        width: parent.width
                        text: win.flow?.supplementaryMessage ?? ""
                        color: (win.flow?.supplementaryIsError ?? false) ? Theme.danger : Theme.textDim
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.Wrap
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: Theme.gap
                    TextButton { text: "Cancel"; onClicked: win.cancel() }
                    TextButton {
                        text: "Authorize"
                        primary: true
                        enabled: win.flow?.isResponseRequired ?? false
                        onClicked: win.submit()
                    }
                }
            }
        }
    }
}
