// Quick panel (Super+A): against the right edge, full height, slides in from the right.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

PanelWindow {
    id: win
    readonly property bool open: Ui.panelOpen

    screen: Ui.screen
    anchors { top: true; right: true; bottom: true }
    implicitWidth: Theme.panelWidth
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: open || sheet.x < Theme.panelWidth

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simpleshell-panel"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // A click outside the panel (or its menu) closes it, except while picking a color (zenity
    // window, eyedropper).
    HyprlandFocusGrab {
        windows: [win, trayMenu]
        active: win.open && !Settings.picking
        onCleared: if (!Settings.picking) Ui.panelOpen = false
    }

    onOpenChanged: if (!open) trayMenu.close()

    Rectangle {
        id: sheet
        width: Theme.panelWidth
        height: parent.height
        color: Theme.bg
        x: win.open ? 0 : Theme.panelWidth

        // Outline on the inner edge, like floating elements.
        Rectangle { width: 1; height: parent.height; color: Theme.outline }
        Behavior on x { id: slide; Anim { drawer: true; entering: slide.targetValue === 0 } }

        focus: win.open
        Keys.onEscapePressed: Ui.panelOpen = false
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Back) Ui.back();
            else if (event.key === Qt.Key_Forward) Ui.forward();
        }

        ColumnLayout {
            anchors { fill: parent; margins: Theme.panelPad }
            spacing: Theme.section

            // Home, or a detail page (Wi-Fi…) in its place; the footer stays.
            ColumnLayout {
                visible: Ui.panelPage === ""
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.section

                Header { Layout.fillWidth: true }
                Tiles { Layout.fillWidth: true }
                Sliders { Layout.fillWidth: true }
                Item { Layout.fillHeight: true }
                Tray { Layout.fillWidth: true; menu: trayMenu }
                Media { Layout.fillWidth: true }
            }
            Loader {
                active: Ui.panelPage === "wifi"
                visible: active
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: "WifiPage.qml"
            }
            Loader {
                active: Ui.panelPage === "bluetooth"
                visible: active
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: "BluetoothPage.qml"
            }
            Loader {
                active: Ui.panelPage === "settings"
                visible: active
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: "SettingsPage.qml"
            }
            Footer { Layout.fillWidth: true }
        }

        NavArea { onBack: Ui.back(); onForward: Ui.forward() }
    }

    TrayMenu { id: trayMenu; panel: win }
}
