// Countdown before a screen recording: "Recording in 3", 2, 1. Gone before the recording starts.
import QtQuick
import ".."
import "../components"
import "../osd"
import "../services"

Osd {
    id: osd
    kind: "capture"
    timeout: 1500   // longer than a second: stays up between two numbers
    cardWidth: message.implicitWidth + Theme.rowPad * 2

    Connections {
        target: Capture
        function onCountdownChanged() {
            if (Capture.countdown > 0) osd.show();
            else osd.shown = false;
        }
    }

    Row {
        id: message
        anchors.centerIn: parent
        spacing: Theme.iconGap
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "video"
            color: Theme.danger
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: "Recording in " + Capture.countdown
            font.weight: Font.Bold
            font.features: ({ "tnum": 1 })
        }
    }
}
