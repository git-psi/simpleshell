// Popup notifications, stacked in the corner picked in Settings (top or bottom, left, center or
// right), the most recent one closest to the edge.
// They go away on their own (except critical ones); hovering pauses the countdown.
// Only the cards take clicks: the rest of the window lets the mouse through.
import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
import "../components"
import "../services"

PanelWindow {
    id: win
    readonly property bool bottom: Settings.notifVertical === "bottom"
    readonly property string side: Settings.notifHorizontal
    // Starting offset of an incoming card: from the nearest edge.
    readonly property int enterX: side === "right" ? Theme.section : side === "left" ? -Theme.section : 0

    screen: Ui.screen
    // Full screen height (only the cards take clicks): the stack stays against its edge without
    // the window moving as it grows. Neither left nor right: centered.
    anchors { top: true; bottom: true; left: side === "left"; right: side === "right" }
    margins { top: Theme.screenMargin; bottom: Theme.screenMargin; left: Theme.screenMargin; right: Theme.screenMargin }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: stack.width
    color: "transparent"
    visible: Notifs.popups.length > 0 && !Ui.notifsOpen
    mask: Region { item: stack }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simpleshell-toasts"

    Column {
        id: stack
        width: Theme.panelWidth - Theme.panelPad * 2
        y: win.bottom ? win.height - height : 0
        spacing: Theme.gap
        // No animation for the first one: the stack just appeared, it's already in place.
        Behavior on y { enabled: Notifs.popups.length > 1; Anim {} }

        // The incoming one slides in; the others shift smoothly to make room for it (or to fill the
        // gap of the one leaving).
        add: Transition {
            Anim { property: "opacity"; from: 0; to: 1 }
            Anim { property: "x"; from: win.enterX; to: 0 }
        }
        move: Transition {
            Anim { property: "y" }
        }

        Repeater {
            // ScriptModel keeps existing cards (a new array would recreate them all).
            model: ScriptModel { values: win.bottom ? [...Notifs.popups].reverse() : Notifs.popups }
            NotificationCard {
                id: toast
                required property var modelData
                width: stack.width
                notification: modelData
                floating: true

                Timer {
                    interval: Notifs.timeoutOf(toast.modelData)
                    running: interval > 0 && !toast.hovered
                    onTriggered: Notifs.hide(toast.modelData)
                }
                onActivated: Notifs.hide(modelData, true)
            }
        }
    }
}
