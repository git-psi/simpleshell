// Apps in simpleshell's colors: reruns apps/theme.sh (GTK, Qt, terminal, cursor, window borders) when
// the light/dark theme or the accent changes. GTK apps already open keep their colors until their
// next launch; Alacritty and the borders change right away.
import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Scope {
    id: root
    readonly property var command: [Quickshell.shellDir + "/apps/theme.sh", Theme.light ? "light" : "dark",
        String(Theme.accent), String(Theme.accentInk), String(Theme.bg), String(Theme.sunken),
        String(Theme.surface), String(Theme.surfaceHi), String(Theme.text), String(Theme.textDim),
        String(Theme.danger)]

    // Groups close changes (scrolling through accents) into a single write.
    onCommandChanged: apply.restart()
    Timer { id: apply; interval: 300; running: true; onTriggered: run.running = true }
    Process {
        id: run
        command: root.command
    }
}
