// A notification, the same in the panel and as a popup: app, time, close; title and body; image
// preview; action buttons (the first one in accent). Click = default action.
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"

Rectangle {
    id: root
    required property var notification
    property bool floating: false        // popup: background of floating elements
    readonly property bool hovered: hover.hovered
    signal activated()                   // after a click on the card or an action

    readonly property var n: notification
    // Attached image: Quickshell gives it as "image://icon//path" for a file. A file outside icon
    // folders (screenshot…) becomes a preview; otherwise (avatar, icon) it replaces the app icon.
    readonly property string imagePath: {
        const s = n.image.replace(/^image:\/\/icon\//, "").replace(/^file:\/\//, "");
        return s.startsWith("/") ? s : "";
    }
    readonly property string preview: imagePath !== "" && !/\/(icons|pixmaps)\//.test(imagePath) ? imagePath : ""
    readonly property var actions: Notifs.buttons(n)

    implicitHeight: content.implicitHeight + Theme.rowPad * 2
    radius: Theme.radius
    color: floating ? Theme.bg : Theme.surface
    border.width: floating ? 1 : 0
    border.color: Theme.outline

    HoverHandler { id: hover }
    StateLayer { area: mouse }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // The action may close the notification, hence destroy this card: run it afterwards.
        onClicked: {
            const n = root.n;
            root.activated();
            Qt.callLater(() => Notifs.activate(n));
        }
    }

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.rowPad }
        spacing: Theme.cardPad

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap
            // The shell's own notifications (USB drive, battery): Lucide icon, "lucide:usb"
            // (notify-send -i stores it as the app icon or as the image depending on the version).
            readonly property string lucide: [root.n.appIcon, root.n.image]
                .map(s => (s ?? "").match(/lucide:([\w-]+)/)).find(m => m)?.[1] ?? ""
            Icon {
                visible: parent.lucide !== ""
                name: parent.lucide
                size: Theme.icon
                color: Theme.textDim
            }
            AppIcon {
                visible: parent.lucide === ""
                size: Theme.icon
                icon: root.n.appIcon || (root.preview === "" ? root.n.image : "")
                    || root.n.desktopEntry || root.n.appName.toLowerCase()
                name: root.n.appName || root.n.summary
            }
            Txt {
                text: root.n.appName || "Notification"
                color: Theme.textDim
                font.pixelSize: Theme.fontSmall
                font.weight: Font.Medium
            }
            // Time only in the history: a popup just arrived.
            Txt {
                Layout.fillWidth: true
                text: root.floating ? "" : Notifs.timeOf(root.n)
                color: Theme.textDim
                font.pixelSize: Theme.fontSmall
            }
            IconButton {
                size: Theme.controlTiny
                flat: true
                icon: "x"
                onClicked: root.n.dismiss()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.n.summary !== "" || root.n.body !== ""
            spacing: Theme.tight
            Txt {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.n.summary
                font.pixelSize: Theme.fontLarge
                font.weight: Font.Bold
                textFormat: Text.PlainText
            }
            Txt {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.n.body
                color: Theme.textDim
                wrapMode: Text.Wrap
                maximumLineCount: 3
                textFormat: Text.PlainText
            }
        }

        RoundedImage {
            visible: root.preview !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? Theme.previewHeight : 0
            radius: Theme.inner(Theme.radius, Theme.inset)
            source: root.preview !== "" ? "file://" + root.preview : ""
        }

        Row {
            id: buttons
            visible: root.actions.length > 0
            Layout.fillWidth: true
            spacing: Theme.gap
            Repeater {
                model: root.actions
                TextButton {
                    required property var modelData
                    required property int index
                    width: (buttons.width - buttons.spacing * (root.actions.length - 1)) / root.actions.length
                    text: modelData.text
                    primary: index === 0
                    onClicked: {
                        const n = root.n, action = modelData;
                        if (!Notifs.keepsOpen(n, action)) root.activated();
                        Qt.callLater(() => Notifs.invoke(n, action));
                    }
                }
            }
        }
    }
}
