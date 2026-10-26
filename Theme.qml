pragma Singleton
// All of the shell's style: colors, font, sizes, radii, spacing, durations.
// No visual value is hard-coded anywhere else: to change the look, this is the place.
import Quickshell
import QtQuick

Singleton {
    // Colors: 4 background grays, 2 text grays, the accent and red. Dark / light theme and accent
    // color come from the Settings page (Settings.qml).
    readonly property bool light: Settings.light
    readonly property color bg: light ? "#f2f2f2" : "#161616"          // panels, floating menus
    readonly property color sunken: light ? "#e8e8e8" : "#1c1c1c"      // sunken inside a card: expanded part, text field
    readonly property color surface: light ? "#ffffff" : "#232323"     // cards, tiles, lists
    readonly property color surfaceHi: light ? "#e2e2e2" : "#2e2e2e"   // buttons, bar and switch tracks
    readonly property color line: light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.06)
    readonly property color text: light ? "#1b1b1b" : "#f2f2f2"
    readonly property color textDim: light ? "#6e6e6e" : "#8e8e8e"     // subtitles, section titles, off state
    // Accent colors offered in Settings (the first one is the default).
    readonly property var accents: ["#4fa3e6", "#9a7ae6", "#4fbe8a", "#e69a4f", "#e66a8c"]
    readonly property color accent: Settings.accent
    // Text and icons drawn on the accent: the same hue, very dark.
    readonly property color accentInk: Qt.hsla(accent.hslHue, accent.hslSaturation, 0.1, 1)
    readonly property color accentInkDim: Qt.rgba(accentInk.r, accentInk.g, accentInk.b, 0.72)
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.12)   // current choice in a list
    readonly property color danger: "#e5534b"
    // 1 px outline of floating elements (menus, OSD, notifications…), setting them apart from the desktop.
    readonly property color outline: surfaceHi
    readonly property color scrim: Qt.rgba(0.04, 0.04, 0.04, 0.5)

    // Opacities
    readonly property real hoverOpacity: 0.05
    readonly property real pressOpacity: 0.10
    readonly property real disabledOpacity: 0.4

    // Font: 4 sizes.
    readonly property string font: "Ubuntu"
    readonly property int fontTitle: 20     // clock, page title, pairing code
    readonly property int fontLarge: 14     // tile or card title (bold)
    readonly property int fontBody: 13      // body text, list rows, buttons
    readonly property int fontSmall: 11     // subtitles, section titles (bold), chips

    // Icons
    readonly property int iconLarge: 24
    readonly property int icon: 18
    readonly property int iconSmall: 16

    // Heights
    readonly property int control: 40        // footer buttons, avatar
    readonly property int controlSmall: 32   // text buttons, back, menu entries
    readonly property int controlTiny: 28    // chips, slider icon, chevrons
    readonly property int tile: 56           // tiles, cover art
    readonly property int row: 48            // list rows
    readonly property int trackHeight: 8     // progress bars
    readonly property int labelWidth: 68    // app name in front of a volume bar
    readonly property int toggleWidth: 42
    readonly property int toggleHeight: 24

    // Radii. Rule: inner radius = outer radius - gap between the two edges.
    readonly property int radiusLarge: 18     // floating containers (power menu)
    readonly property int radius: 14          // cards, tiles, menus
    readonly property int radiusControl: 10   // 40 px buttons
    readonly property int radiusSmall: 8      // buttons of 32 px and less, fields
    readonly property int radiusTrack: 3      // progress bars
    function inner(outer, gap) { return Math.max(2, outer - gap) }

    // Spacing
    readonly property int panelWidth: 420
    readonly property int panelPad: 20    // panel edge
    readonly property int section: 14     // between two blocks
    readonly property int rowPad: 16      // row or tile edge to an icon or text
                                          // (to a 32 px button: gap, same space as above it)
    readonly property int iconGap: 12     // between an icon and its text
    readonly property int cardPad: 10     // inner edge of a card
    readonly property int gap: 8          // between neighboring elements
    readonly property int inset: 4        // inset of a hover background in a card
    readonly property int tight: 2        // between two lines of text

    // Floating windows
    readonly property int menuWidth: 240
    readonly property int menuRows: 14        // visible menu entries before scrolling
    readonly property int launcherWidth: 600
    readonly property int dialogWidth: 400     // administrator password prompt
    readonly property int launcherTop: 240     // distance from the top of the screen: doesn't move when the list changes
    readonly property int launcherRows: 6      // visible results before scrolling
    readonly property int osdWidth: 300
    readonly property int osdMargin: 40
    readonly property int powerButton: 112
    readonly property int previewHeight: 150   // image preview in a notification

    // Gap between a floating element and the screen edge
    readonly property int screenMargin: 28

    // Motion: fast and without bounce, Emil Kowalski's curves. Everything starts fast and settles
    // softly: curveOut for what appears or disappears (never an ease-in at the start, which feels
    // like lag), curveDrawer (iOS-like) for panels sliding in from an edge. Exits are shorter than
    // entrances. Same curves for windows (hypr/simpleshell.lua) and hyprlock. Ready-made animation:
    // components/Anim.qml.
    readonly property var curveOut: [0.23, 1, 0.32, 1, 1, 1]
    readonly property var curveDrawer: [0.32, 0.72, 0, 1, 1, 1]
    readonly property int durFast: 80        // hover, bar following a value
    readonly property int dur: 140           // state changes (colors, switches)
    readonly property int durIn: 200         // entrances (OSD, notifications, power menu)
    readonly property int durOut: 140        // exits
    readonly property int durDrawer: 300     // panel sliding in from an edge
    readonly property int durDrawerOut: 200  // and sliding out
    readonly property int durPop: 260        // power menu: buttons growing as they appear
    readonly property int stagger: 30        // delay between the buttons of that cascade
    readonly property real popFrom: 0.95     // starting scale of what grows in
    readonly property int osdTimeout: 1400
    readonly property int osdLabelTimeout: 2500   // OSD with a label (profile, mic…): time to read it
}
