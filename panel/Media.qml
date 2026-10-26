// Music player: cover art, title, progress, controls. Hidden without a player.
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../Format.js" as Format

Rectangle {
    id: root
    // playerctld only relays the real player: it would be a duplicate.
    readonly property var players: Mpris.players.values.filter(p => !p.dbusName.endsWith(".playerctld"))
    property string chosen: ""      // player picked by hand (click on its name)
    readonly property var player: players.find(p => p.dbusName === chosen)
        ?? players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
    // Track length. Firefox forgets it after seeking (no length until the next track): keep the
    // last known one while the title doesn't change.
    property real length: 0
    property string lengthTrack: ""
    function syncLength() {
        const title = player?.trackTitle ?? "";
        if (player?.lengthSupported && player.length > 0) length = player.length;
        else if (title !== lengthTrack) length = 0;
        lengthTrack = title;
    }
    readonly property int innerRadius: Theme.inner(Theme.radius, Theme.cardPad)
    // While dragging the bar: target fraction (-1 = not dragging).
    property real dragFraction: -1
    // Position: the last value given by the player (seek, track, play/pause), then advanced by us
    // frame by frame (Firefox sometimes reports a rate of 0).
    property real basePos: 0
    property real baseTime: 0
    property real now: 0
    readonly property real position: {
        const p = basePos + (playing ? (now - baseTime) / 1000 * (player?.rate || 1) : 0);
        return length > 0 ? Math.min(p, length) : p;
    }
    readonly property real progress: length > 0 ? position / length : 0
    function rebase() {
        basePos = player?.position ?? 0;
        baseTime = Date.now();
        now = baseTime;
    }
    onPlayerChanged: { syncLength(); rebase(); }
    onPlayingChanged: rebase()
    Connections {
        target: root.player
        function onPositionChanged() { root.rebase(); }
        function onPostTrackChanged() { root.syncLength(); root.rebase(); }
        function onTrackTitleChanged() { root.syncLength(); }
        function onLengthChanged() { root.syncLength(); }
        function onLengthSupportedChanged() { root.syncLength(); }
    }
    FrameAnimation {
        running: Ui.panelOpen && root.playing && root.visible
        onTriggered: root.now = Date.now()
    }

    visible: player !== null && Settings.showMedia
    implicitHeight: content.implicitHeight + Theme.cardPad * 2
    radius: Theme.radius
    color: Theme.surface

    function nextPlayer() {
        if (players.length < 2) return;
        chosen = players[(players.indexOf(player) + 1) % players.length].dbusName;
    }

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.cardPad }
        spacing: Theme.cardPad

        RowLayout {
            spacing: Theme.iconGap

            Rectangle {
                id: art
                Layout.preferredWidth: Theme.tile
                Layout.preferredHeight: Theme.tile
                radius: root.innerRadius
                color: Theme.bg
                Icon {
                    anchors.centerIn: parent
                    visible: !cover.ready
                    name: "music"
                    size: Theme.iconLarge
                    color: Theme.textDim
                }
                RoundedImage {
                    id: cover
                    anchors.fill: parent
                    radius: parent.radius
                    source: root.player?.trackArtUrl ?? ""
                }
            }

            TwoLines {
                Layout.fillWidth: true
                title: root.player?.trackTitle || "Now playing"
                sub: root.player?.trackArtist ?? ""
                strong: true
            }

            Txt {
                Layout.alignment: Qt.AlignTop
                text: root.player?.identity ?? ""
                color: Theme.textDim
                font.pixelSize: Theme.fontSmall
                MouseArea {
                    anchors.fill: parent
                    enabled: root.players.length > 1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextPlayer()
                }
            }
        }

        // Progress: drag to seek, the track only changes on release.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.iconSmall
            Bar {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                value: root.dragFraction >= 0 ? root.dragFraction : root.progress
            }
            MouseArea {
                anchors.fill: parent
                enabled: (root.player?.canSeek ?? false) && root.length > 0
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                function track(x) { root.dragFraction = Math.max(0, Math.min(1, x / width)); }
                onPressed: (mouse) => track(mouse.x)
                onPositionChanged: (mouse) => track(mouse.x)
                onReleased: {
                    root.player.position = root.length * root.dragFraction;
                    root.dragFraction = -1;
                    root.rebase();
                }
                onCanceled: root.dragFraction = -1
            }
        }

        RowLayout {
            Txt {
                Layout.preferredWidth: Theme.control
                text: Format.time(root.dragFraction >= 0 ? root.length * root.dragFraction : root.position)
                color: Theme.textDim
                font.pixelSize: Theme.fontSmall
                font.features: ({ "tnum": 1 })
            }
            Item { Layout.fillWidth: true }
            Row {
                spacing: Theme.inset
                MediaButton {
                    icon: "shuffle"
                    on: root.player?.shuffle ?? false
                    enabled: root.player?.shuffleSupported ?? false
                    onClicked: root.player.shuffle = !root.player.shuffle
                }
                MediaButton {
                    icon: "skip-back"; filled: true
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }
                IconButton {
                    size: Theme.controlSmall
                    primary: true
                    icon: root.playing ? "pause" : "play"
                    filled: true
                    onClicked: root.player.togglePlaying()
                }
                MediaButton {
                    icon: "skip-forward"; filled: true
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }
                MediaButton {
                    icon: root.player?.loopState === MprisLoopState.Track ? "repeat-1" : "repeat"
                    on: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                    enabled: root.player?.loopSupported ?? false
                    onClicked: {
                        const s = root.player.loopState;
                        root.player.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist
                            : s === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Txt {
                Layout.preferredWidth: Theme.control
                horizontalAlignment: Text.AlignRight
                text: root.length > 0 ? Format.time(root.length) : ""
                color: Theme.textDim
                font.pixelSize: Theme.fontSmall
                font.features: ({ "tnum": 1 })
            }
        }
    }

    // Subtle button; the filled controls (previous, next) keep a bright icon.
    component MediaButton: IconButton {
        size: Theme.controlSmall
        flat: true
        iconColor: on ? Theme.accent : filled ? Theme.text : Theme.textDim
    }
}
