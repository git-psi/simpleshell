// Power menu (Super+Escape): five big buttons in the middle of the screen.
import QtQuick
import ".."
import "../components"

ActionMenu {
    id: menu
    name: "power"
    open: Ui.powerOpen
    actions: [
        { icon: "lock",      label: "Lock",      command: "lock" },
        { icon: "moon",      label: "Sleep",     command: "suspend" },
        { icon: "log-out",   label: "Log out",   command: "logout" },
        { icon: "power",     label: "Shut down", command: "poweroff" },
        { icon: "rotate-cw", label: "Restart",   command: "reboot" }
    ]
    onPicked: (i) => {
        Ui.powerOpen = false;
        Config.run(actions[i].command);
    }
    onDismissed: Ui.powerOpen = false
}
