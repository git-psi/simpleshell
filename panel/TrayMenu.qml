// Menu of a background app, shown left of the panel, level with its chip.
// A submenu opens in place of the menu, with a "back" row at the top.
import Quickshell
import QtQml
import QtQuick
import ".."
import "../components"

PopupWindow {
    id: root
    property var panel
    property var item: null
    property var stack: []      // open submenus, from the first to the deepest
    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : item?.menu ?? null

    readonly property int room: Theme.gap
    readonly property int pad: Theme.inset

    function toggle(trayItem, chip) {
        if (visible && item === trayItem) { close(); return; }
        item = trayItem;
        stack = [];
        left = [];
        visited = [];
        const bottom = chip.mapToItem(null, 0, chip.height).y;
        anchor.rect.x = 0;
        anchor.rect.y = bottom + room;
        anchor.rect.width = 1;
        anchor.rect.height = 1;
        visible = true;
    }
    function close() {
        visible = false;
        item = null;
        stack = [];
        left = [];
        visited = [];
    }

    anchor.window: panel
    anchor.edges: Edges.Left | Edges.Top
    anchor.gravity: Edges.Left | Edges.Top
    color: "transparent"
    implicitWidth: card.width + room + Theme.cardPad
    implicitHeight: card.height + room * 2

    // One "opener" per visited submenu: the main menu stays open while in a submenu (otherwise its
    // entries, hence the submenu, vanish), and a submenu left with "back" stays open until the
    // menu closes, so it can be returned to.
    property var visited: []
    function enter(entry) {
        if (!visited.includes(entry)) visited = visited.concat([entry]);
        stack = stack.concat([entry]);
    }
    // Back/forward: "left" keeps the submenus that were left, to return to them.
    property var left: []
    function back() {
        if (stack.length === 0) return;
        left = left.concat([current]);
        stack = stack.slice(0, -1);
    }
    function forward() {
        if (left.length === 0) return;
        enter(left[left.length - 1]);
        left = left.slice(0, -1);
    }
    QsMenuOpener { id: rootOpener; menu: root.item?.menu ?? null }
    Instantiator {
        id: subOpeners
        model: root.visited
        delegate: QsMenuOpener {
            required property var modelData
            menu: modelData
        }
    }
    readonly property var shown: {
        if (stack.length === 0) return rootOpener;
        for (let i = 0; i < subOpeners.count; i++) {
            const o = subOpeners.objectAt(i);
            if (o && o.menu === current) return o;
        }
        return null;
    }

    Rectangle {
        id: card
        anchors { right: parent.right; rightMargin: Theme.cardPad; top: parent.top; topMargin: root.room }
        width: Theme.menuWidth
        height: list.implicitHeight + root.pad * 2
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.outline

        Column {
            id: list
            anchors { fill: parent; margins: root.pad }

            // Back to the previous menu, inside a submenu.
            Item {
                visible: root.stack.length > 0
                width: list.width
                height: Theme.controlSmall
                StateLayer { area: backMouse; radius: Theme.inner(Theme.radius, root.pad) }
                Icon {
                    id: back
                    anchors { left: parent.left; leftMargin: Theme.gap; verticalCenter: parent.verticalCenter }
                    name: "chevron-left"
                    size: Theme.iconSmall
                    color: Theme.textDim
                }
                Txt {
                    anchors { left: back.right; leftMargin: Theme.inset; right: parent.right; verticalCenter: parent.verticalCenter }
                    text: (root.current?.text ?? "").replace(/_(?!_)/g, "")
                    color: Theme.textDim
                    font.weight: Font.Medium
                }
                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.back()
                }
            }

            // Long menus (list of updates…) scroll instead of overflowing the screen.
            ListView {
                id: entries
                width: list.width
                height: Math.min(contentHeight, Theme.menuRows * Theme.controlSmall)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.shown?.children ?? null
                delegate: Item {
                    id: entry
                    required property var modelData
                    readonly property bool separator: modelData.isSeparator
                    width: entries.width
                    height: separator ? Theme.gap + 1 : Theme.controlSmall

                    Separator {
                        visible: entry.separator
                        anchors.centerIn: parent
                        width: parent.width - Theme.rowPad
                    }
                    StateLayer {
                        visible: !entry.separator && entry.modelData.enabled
                        radius: Theme.inner(Theme.radius, root.pad)
                        area: entryMouse
                    }
                    Txt {
                        visible: !entry.separator
                        anchors { left: parent.left; leftMargin: Theme.cardPad; right: arrow.left; rightMargin: Theme.inset; verticalCenter: parent.verticalCenter }
                        text: (entry.modelData.text ?? "").replace(/_(?!_)/g, "")
                        opacity: entry.modelData.enabled ? 1 : Theme.disabledOpacity
                    }
                    // Chevron for a submenu, check mark for a checked option.
                    Icon {
                        id: arrow
                        readonly property bool checked: entry.modelData.checkState === Qt.Checked
                        visible: (entry.modelData.hasChildren ?? false) || checked
                        anchors { right: parent.right; rightMargin: Theme.gap; verticalCenter: parent.verticalCenter }
                        name: entry.modelData.hasChildren ? "chevron-right" : "check"
                        size: Theme.iconSmall
                        color: checked ? Theme.accent : Theme.textDim
                    }
                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        enabled: !entry.separator && entry.modelData.enabled
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (entry.modelData.hasChildren) {
                                root.left = [];
                                root.enter(entry.modelData);
                                return;
                            }
                            entry.modelData.triggered();
                            root.close();
                        }
                    }
                }
            }
        }

        NavArea { onBack: root.back(); onForward: root.forward() }
    }
}
