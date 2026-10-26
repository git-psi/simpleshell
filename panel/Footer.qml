// Panel footer: user on the left, actions on the right.
import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"
import "../Format.js" as Format

RowLayout {
    spacing: Theme.gap

    Rectangle {
        Layout.preferredWidth: Theme.control
        Layout.preferredHeight: Theme.control
        radius: Theme.radiusControl
        color: Theme.surfaceHi
        Icon { anchors.centerIn: parent; name: "user" }
    }
    TwoLines {
        Layout.leftMargin: Theme.inset
        Layout.fillWidth: true
        title: Quickshell.env("USER") ?? ""
        strong: true
        sub: Capture.recording ? Format.time(Capture.elapsed) : ""   // recording time
        subColor: Theme.danger
    }

    // Capture menu; while recording, stops it.
    IconButton {
        icon: Capture.busy ? "circle-stop" : "camera"
        iconColor: Capture.busy ? Theme.danger : Theme.text
        onClicked: Capture.key()
    }

    IconButton {
        icon: "sliders-horizontal"
        onClicked: Ui.panelPage === "settings" ? Ui.back() : Ui.panelPage = "settings"
    }
    IconButton {
        icon: "lock"
        onClicked: { Ui.panelOpen = false; Config.run("lock"); }
    }
    IconButton {
        icon: "moon"
        onClicked: { Ui.panelOpen = false; Config.run("suspend"); }
    }
    IconButton {
        icon: "log-out"
        onClicked: Config.run("logout")
    }
    IconButton {
        icon: "power"
        iconColor: Theme.danger
        onClicked: Ui.togglePower()
    }
}
