// Expanded part of a volume row (quick panel), on a darker background: the device list (the one
// in use on a light accent background, with a check mark), then whatever is declared inside
// (app volumes).
import Quickshell
import QtQuick
import ".."
import "../components"
import "../services"

Rectangle {
    id: drawer
    property string title
    property var devices: []
    property var current: null
    default property alias content: extra.data

    readonly property int innerRadius: Theme.inner(Theme.radius, Theme.cardPad)
    readonly property int rowInset: Theme.cardPad - Theme.inset

    implicitHeight: body.implicitHeight
    radius: innerRadius
    color: Theme.sunken

    Column {
        id: body
        width: parent.width
        topPadding: Theme.cardPad
        bottomPadding: Theme.cardPad
        spacing: Theme.gap

        SectionLabel {
            x: Theme.cardPad
            width: parent.width - Theme.cardPad * 2
            text: drawer.title
        }
        Column {
            x: drawer.rowInset
            width: parent.width - drawer.rowInset * 2
            // A small gap between rows: the hover doesn't stick to the chosen device's background.
            spacing: Theme.inset
            Repeater {
                model: ScriptModel { values: drawer.devices }
                Rectangle {
                    id: device
                    required property var modelData
                    readonly property bool chosen: modelData === drawer.current
                    width: parent.width
                    height: Theme.row
                    radius: Theme.inner(drawer.innerRadius, drawer.rowInset)
                    color: chosen ? Theme.accentSoft : "transparent"

                    TwoLines {
                        anchors {
                            left: parent.left; leftMargin: Theme.cardPad
                            right: check.left; rightMargin: Theme.cardPad
                            verticalCenter: parent.verticalCenter
                        }
                        title: Audio.label(device.modelData)
                        // The connection type only when it tells something (not "Built-in").
                        sub: Audio.kind(device.modelData) === "Built-in" ? "" : Audio.kind(device.modelData)
                    }
                    Icon {
                        id: check
                        visible: device.chosen
                        anchors { right: parent.right; rightMargin: Theme.cardPad; verticalCenter: parent.verticalCenter }
                        name: "check"
                        size: Theme.iconSmall
                        color: Theme.accent
                    }
                    StateLayer { area: mouse }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        enabled: !device.chosen
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.setDefault(device.modelData)
                    }
                }
            }
        }
        Column {
            id: extra
            width: parent.width
            spacing: Theme.gap
        }
    }
}
