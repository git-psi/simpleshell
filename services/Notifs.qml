pragma Singleton
// Notification server (org.freedesktop.Notifications): history, popups (in the corner picked in
// Settings) and Do not disturb.
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import ".."

Singleton {
    id: root
    // Most recent first.
    readonly property var list: [...server.trackedNotifications.values].reverse()
    readonly property int count: list.length
    // Currently shown as popups (most recent first).
    property var popups: []
    readonly property int maxPopups: 3
    readonly property int defaultTimeout: 5000

    // Arrival time of each notification (by id).
    property var times: ({})

    function timeOf(n) {
        const t = times[n.id];
        return t ? Qt.formatTime(new Date(t), "HH:mm") : "";
    }
    // Popup display time, in ms; 0 = until dismissed.
    function timeoutOf(n) {
        if (n.urgency === NotificationUrgency.Critical) return 0;
        return n.expireTimeout > 0 ? n.expireTimeout : defaultTimeout;
    }
    // The "default" action is clicking the notification; the others are buttons.
    function buttons(n) { return n ? n.actions.filter(a => a.identifier !== "default") : []; }
    function activate(n) {
        const def = n.actions.find(a => a.identifier === "default");
        if (def) def.invoke();
        else if (n.desktopEntry !== "") Quickshell.execDetached(["gtk-launch", n.desktopEntry]);
        if (!n.resident) n.dismiss();
    }
    // Actions that don't lead elsewhere (Delete…) leave the panel open: the sender lists their keys
    // in the "x-simpleshell-keep-open" hint, comma-separated.
    function keepsOpen(n, action) {
        return String(n.hints["x-simpleshell-keep-open"] ?? "").split(",").includes(action.identifier);
    }
    function invoke(n, action) {
        action.invoke();
        if (!n.resident) n.dismiss();
    }
    // keep: don't close it (it was just acted upon, the app takes care of it).
    function hide(n, keep) {
        if (!popups.includes(n)) return;      // already closed
        popups = popups.filter(p => p !== n);
        // Transient by nature: it doesn't go into the history.
        if (!keep && n.transient) n.expire();
    }
    function clear() {
        // Copy first: each dismissal removes the notification from the tracked list.
        const all = [...list];
        popups = [];
        for (const n of all) if (n?.tracked) n.dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        persistenceSupported: true

        onNotification: (n) => {
            n.tracked = true;
            const t = Object.assign({}, root.times);
            t[n.id] = Date.now();
            root.times = t;
            n.closed.connect(() => { root.popups = root.popups.filter(p => p !== n); });
            // Do not disturb lets critical ones through; with the panel open, it already shows there.
            if ((Ui.dnd && n.urgency !== NotificationUrgency.Critical) || Ui.notifsOpen) return;
            root.popups = [n].concat(root.popups.filter(p => p.id !== n.id)).slice(0, root.maxPopups);
        }
    }

    // Opening the panel or enabling Do not disturb clears the popups.
    Connections {
        target: Ui
        function onNotifsOpenChanged() { if (Ui.notifsOpen) root.popups = []; }
        function onDndChanged() {
            if (Ui.dnd) root.popups = root.popups.filter(n => n.urgency === NotificationUrgency.Critical);
        }
    }
}
