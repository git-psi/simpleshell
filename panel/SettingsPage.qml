// Settings page of the panel: appearance (accent, theme, night light, wallpaper), idle, launcher,
// notifications, what the panel shows, and shortcuts to the configuration files.
import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

ColumnLayout {
    id: root
    spacing: Theme.section

    PageHeader {
        Layout.fillWidth: true
        title: "Settings"
        showToggle: false
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: body
            width: parent.width
            spacing: Theme.section

            SettingsGroup {
                title: "Appearance"
                SettingRow {
                    first: true
                    text: "Accent color"
                    // Offered colors, then the current accent if it's not one of them, then the
                    // color picker (palette) and the eyedropper (anywhere on screen).
                    Row {
                        spacing: Theme.inset + Theme.tight
                        Repeater {
                            model: Theme.accents
                            Swatch {
                                required property string modelData
                                color: modelData
                                chosen: Qt.colorEqual(modelData, Theme.accent)
                                onClicked: Settings.accent = modelData
                            }
                        }
                        Swatch {
                            visible: !Theme.accents.some(a => Qt.colorEqual(a, Theme.accent))
                            color: Theme.accent
                            chosen: true
                        }
                        Swatch { icon: "palette"; onClicked: Settings.pickAccent() }
                        Swatch { icon: "pipette"; onClicked: Settings.pickAccentOnScreen() }
                    }
                }
                SettingRow {
                    text: "Theme"
                    Segmented {
                        options: ["Dark", "Light"]
                        current: Settings.light ? 1 : 0
                        onPicked: (i) => Settings.light = i === 1
                    }
                }
                SettingRow {
                    text: "Night light"
                    Segmented {
                        readonly property var values: [5000, 4000, 3000]
                        options: ["Low", "Medium", "High"]
                        current: values.indexOf(Settings.nightTemperature)
                        onPicked: (i) => Settings.nightTemperature = values[i]
                    }
                }
                SettingRow {
                    text: "Wallpaper"
                    sub: Settings.wallpaper !== "" ? Settings.wallpaper.split("/").pop() : "None"
                    Row {
                        spacing: Theme.gap
                        TextButton {
                            visible: Settings.wallpaper !== ""
                            text: "Remove"
                            onClicked: Settings.wallpaper = ""
                        }
                        TextButton {
                            text: "Choose…"
                            onClicked: { Ui.panelOpen = false; Settings.pickWallpaper(); }
                        }
                    }
                }
                SettingRow {
                    text: "Login screen"
                    sub: Settings.sddmFailed ? "Sync failed" : ""
                    TextButton {
                        text: "Sync"
                        enabled: !Settings.sddmSyncing
                        onClicked: Settings.syncSddm()
                    }
                }
            }

            SettingsGroup {
                title: "Idle"
                // Idle delays, in minutes (0 = never).
                Repeater {
                    model: [
                        { text: "Lock", key: "lockMinutes", values: [1, 5, 10, 0] },
                        { text: "Screen off", key: "screenOffMinutes", values: [2, 5, 10, 0] },
                        { text: "Suspend", key: "suspendMinutes", values: [15, 30, 60, 0] }
                    ]
                    SettingRow {
                        id: delay
                        required property var modelData
                        required property int index
                        first: index === 0
                        text: modelData.text
                        Segmented {
                            options: delay.modelData.values.map(v => v > 0 ? v + " min" : "Never")
                            current: delay.modelData.values.indexOf(Settings[delay.modelData.key])
                            onPicked: (i) => Settings[delay.modelData.key] = delay.modelData.values[i]
                        }
                    }
                }
            }

            SettingsGroup {
                title: "Launcher"
                SettingRow {
                    first: true
                    text: "Web search"
                    sub: "Space, then the text"
                    Segmented {
                        options: Config.searchEngines.map(e => e.name)
                        current: Config.searchEngines.findIndex(e => e.key === Settings.searchEngine)
                        onPicked: (i) => Settings.searchEngine = Config.searchEngines[i].key
                    }
                }
            }

            SettingsGroup {
                title: "Notifications"
                SettingRow {
                    first: true
                    text: "Vertical position"
                    Segmented {
                        readonly property var values: ["top", "bottom"]
                        options: ["Top", "Bottom"]
                        current: values.indexOf(Settings.notifVertical)
                        onPicked: (i) => Settings.notifVertical = values[i]
                    }
                }
                SettingRow {
                    text: "Horizontal position"
                    Segmented {
                        readonly property var values: ["left", "center", "right"]
                        options: ["Left", "Center", "Right"]
                        current: values.indexOf(Settings.notifHorizontal)
                        onPicked: (i) => Settings.notifHorizontal = values[i]
                    }
                }
            }

            SettingsGroup {
                title: "Panel"
                OptionRow {
                    text: "Background apps"
                    checked: Settings.showTray
                    onToggled: Settings.showTray = !Settings.showTray
                }
                OptionRow {
                    first: false
                    text: "Music player"
                    checked: Settings.showMedia
                    onToggled: Settings.showMedia = !Settings.showMedia
                }
                OptionRow {
                    first: false
                    text: "Battery percentage"
                    checked: Settings.batteryPercent
                    onToggled: Settings.batteryPercent = !Settings.batteryPercent
                }
                OptionRow {
                    first: false
                    text: "Seconds on the clock"
                    checked: Settings.clockSeconds
                    onToggled: Settings.clockSeconds = !Settings.clockSeconds
                }
            }

            SettingsGroup {
                title: "Configuration"
                Repeater {
                    model: Config.configFiles
                    SettingRow {
                        required property var modelData
                        required property int index
                        first: index === 0
                        text: modelData.title
                        sub: modelData.path.replace(Quickshell.env("HOME"), "~")
                        clickable: true
                        onClicked: { Ui.panelOpen = false; Quickshell.execDetached(["xdg-open", modelData.path]); }
                        Txt {
                            text: "Open"
                            color: Theme.textDim
                            font.pixelSize: Theme.fontSmall
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }

    // Color square (checked if it's the accent) or icon button of the same size.
    component Swatch: Rectangle {
        property bool chosen: false
        property string icon: ""
        signal clicked()
        width: Theme.iconLarge
        height: Theme.iconLarge
        radius: Theme.inner(Theme.radiusSmall, Theme.tight)
        color: Theme.surfaceHi
        Icon {
            visible: parent.chosen || parent.icon !== ""
            anchors.centerIn: parent
            name: parent.icon !== "" ? parent.icon : "check"
            size: Theme.iconSmall
            color: parent.icon !== "" ? Theme.textDim : Theme.accentInk
        }
        MouseArea {
            id: swatchArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
        StateLayer { area: swatchArea }
    }
}
