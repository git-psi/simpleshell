// App launcher (Super+Space): a search field and the list of matching apps.
// Starting with a space searches the text on the web, in the default browser.
// Arrows or Tab to pick, Enter to launch, Escape or click outside to close.
// Opens without animation. The window only exists while open: a full-screen layer left on screen,
// even transparent, makes the compositor draw it and prevents direct scanout (fullscreen video).
import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
import "../components"
import "../services"

PanelWindow {
    id: win
    readonly property bool open: Ui.launcherOpen
    property string query: ""
    property int current: 0
    readonly property bool web: query.startsWith(" ") && query.trim() !== ""
    readonly property var results: web ? [{ web: true }] : Apps.search(query)

    function launch(item) {
        if (!item) return;
        Ui.launcherOpen = false;
        if (item.web) Apps.webSearch(query.trim());
        else if (item.reload) Apps.reload();
        else item.execute();
    }
    function move(step) {
        if (results.length === 0) return;
        current = (current + step + results.length) % results.length;
        list.positionViewAtIndex(current, ListView.Contain);
    }

    screen: Ui.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simpleshell-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open) { query = ""; input.text = ""; current = 0; input.forceActiveFocus(); }
    onQueryChanged: { current = 0; list.positionViewAtBeginning(); }

    MouseArea {
        id: catcher
        anchors.fill: parent
        onClicked: Ui.launcherOpen = false
    }

    Rectangle {
        id: box
        readonly property int pad: Theme.gap
        x: (parent.width - width) / 2
        y: Theme.launcherTop
        width: Theme.launcherWidth
        height: column.implicitHeight + pad * 2
        radius: Theme.radiusLarge
        color: Theme.bg
        border.width: 1
        border.color: Theme.outline

        visible: win.open

        MouseArea { anchors.fill: parent }   // a click inside the frame doesn't close the launcher

        Column {
            id: column
            x: box.pad
            y: box.pad
            width: parent.width - box.pad * 2

            // Search
            Rectangle {
                width: parent.width
                height: Theme.tile - Theme.cardPad
                radius: Theme.inner(Theme.radiusLarge, box.pad)
                color: Theme.surface
                Icon {
                    id: glass
                    anchors { left: parent.left; leftMargin: Theme.rowPad; verticalCenter: parent.verticalCenter }
                    name: "search"
                    color: Theme.textDim
                }
                TextInput {
                    id: input
                    anchors {
                        left: glass.right; leftMargin: Theme.iconGap
                        right: parent.right; rightMargin: Theme.rowPad
                        verticalCenter: parent.verticalCenter
                    }
                    color: Theme.text
                    cursorDelegate: Rectangle { width: Theme.tight; color: Theme.accent }
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentInk
                    font.family: Theme.font
                    font.pixelSize: Theme.fontLarge
                    font.weight: Font.Medium
                    clip: true
                    focus: win.open
                    onTextChanged: win.query = text
                    Keys.onEscapePressed: Ui.launcherOpen = false
                    Keys.onDownPressed: win.move(1)
                    Keys.onUpPressed: win.move(-1)
                    Keys.onTabPressed: win.move(1)
                    Keys.onBacktabPressed: win.move(-1)
                    Keys.onReturnPressed: win.launch(win.results[win.current])
                    Keys.onEnterPressed: win.launch(win.results[win.current])
                    Txt {
                        visible: input.text === ""
                        text: "Search for an app"
                        color: Theme.textDim
                        font.pixelSize: Theme.fontLarge
                    }
                }
            }

            // Nothing until something is typed; results come right below the field.
            Item { width: parent.width; height: Theme.inset; visible: list.count > 0 }

            ListView {
                id: list
                width: parent.width
                height: Math.min(count, Theme.launcherRows) * Theme.row
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: win.results
                delegate: Rectangle {
                    id: item
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === win.current
                    width: list.width
                    height: Theme.row
                    radius: Theme.inner(Theme.radiusLarge, box.pad)
                    color: selected ? Theme.accentSoft : "transparent"

                    readonly property bool web: item.modelData.web === true
                    readonly property bool reload: item.modelData.reload === true
                    AppIcon {
                        id: appIcon
                        anchors { left: parent.left; leftMargin: Theme.iconGap; verticalCenter: parent.verticalCenter }
                        size: Theme.controlTiny
                        icon: item.web ? (Apps.browser?.icon ?? "") : item.reload ? "" : item.modelData.icon
                        name: item.web ? (Apps.browser?.name ?? "Web") : item.reload ? "" : item.modelData.name
                    }
                    // Reload apps: the empty gray square, with a Lucide icon.
                    Icon {
                        visible: item.reload
                        anchors.centerIn: appIcon
                        size: Theme.iconSmall
                        name: item.reload ? "rotate-cw" : ""
                    }
                    Txt {
                        anchors {
                            left: appIcon.right; leftMargin: Theme.iconGap
                            right: kind.left; rightMargin: Theme.iconGap
                            verticalCenter: parent.verticalCenter
                        }
                        text: item.web ? win.query.trim() : item.modelData.name
                        font.pixelSize: Theme.fontLarge
                        font.weight: Font.Medium
                    }
                    Txt {
                        id: kind
                        anchors { right: parent.right; rightMargin: Theme.iconGap; verticalCenter: parent.verticalCenter }
                        width: Math.min(implicitWidth, list.width / 3)
                        text: item.web ? "Search with " + (Apps.browser?.name ?? "the browser") : Apps.kind(item.modelData)
                        color: Theme.textDim
                        font.pixelSize: Theme.fontSmall
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // Hover picks the row, like the arrows: a single highlight on screen.
                        onPositionChanged: win.current = item.index
                        onClicked: win.launch(item.modelData)
                    }
                }
            }
        }
    }
}
