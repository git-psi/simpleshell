pragma Singleton
// Shared UI state (what is open, the toggles).
import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    property bool panelOpen: false
    property bool powerOpen: false
    property bool notifsOpen: false
    property bool launcherOpen: false
    property bool captureOpen: false
    property string panelPage: ""   // panel detail page ("wifi"), empty = home
    property string osdKind: ""       // OSD shown ("status", "workspace"): one at a time
    property string nextPage: ""    // page left with "back", reopened with "forward"

    property bool dnd: false          // Do not disturb: no more popup notifications
    property bool nightLight: false
    property bool caffeine: false
    property bool touchpad: true      // turned on/off by Hyprland (simpleshell.lua), which tells us

    // Screen where the panel, menus and OSD open: the focused one.
    readonly property var screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    // Only one panel or menu open at a time.
    function togglePanel() {
        const open = !panelOpen;
        closeAll();
        panelOpen = open;
    }
    function toggleNotifs() {
        const open = !notifsOpen;
        closeAll();
        notifsOpen = open;
    }
    // Touchpad, four fingers: swipe right for notifications (on the left), swipe left for the
    // quick panel (on the right). The other way closes whatever is open.
    function swipe(toRight) {
        if (toRight ? panelOpen : notifsOpen) closeAll();
        else if (toRight) toggleNotifs();
        else togglePanel();
    }
    function toggleLauncher() {
        const open = !launcherOpen;
        closeAll();
        launcherOpen = open;
    }
    function togglePower() {
        const open = !powerOpen;
        closeAll();
        powerOpen = open;
    }
    // Back/forward (chevron, mouse buttons, Back/Forward keys): pages are one level deep, so
    // there is only one page to remember.
    function back() {
        if (panelPage === "") return;
        nextPage = panelPage;
        panelPage = "";
    }
    function forward() {
        if (panelPage === "" && nextPage !== "") panelPage = nextPage;
    }
    function closeAll() {
        panelOpen = false;
        notifsOpen = false;
        launcherOpen = false;
        powerOpen = false;
        captureOpen = false;
        panelPage = "";
        nextPage = "";
    }
}
