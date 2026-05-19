pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.VectorImage
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Effects

import "config" as Config
import "pages"
import "components"

ApplicationWindow {
    id: mainWindow

    Universal.theme: Config.StaticData.isDark ? Universal.Dark : Universal.Light

    // portraitMode is now provided by Config.Responsive.portrait
    property StartPage startPage: StartPage {}
    property SideMenu sideMenu: SideMenu {}
    width: 390
    height: 844
    // TRY to center the window, doesn't work on my Ubuntu but should work on other platforms.
    visible: true
    title: qsTr("PokerTH - v2.1.0preview")

    // Keep Responsive singleton in sync with the actual window dimensions
    onWidthChanged: {
        Config.Responsive.windowWidth = width
        Config.Theme.windowWidth      = width
    }
    onHeightChanged: {
        Config.Responsive.windowHeight = height
        Config.Theme.windowHeight      = height
    }

    Component.onCompleted: {
        Config.Responsive.windowWidth  = width
        Config.Responsive.windowHeight = height
        Config.Theme.windowWidth       = width
        Config.Theme.windowHeight      = height
        x = screen.width / 2 - width / 2
        y = screen.height / 2 - height / 2
        LanguageManager.switchLanguage(Config.Parameters.language)
        // Initialise dark/light mode from stored preference
        var dm = SettingsManager ? SettingsManager.readConfigInt("DarkMode") : 1
        Config.StaticData.darkMode = dm
        Config.Theme.darkMode = dm
    }
    
    Rectangle {
        anchors.fill: parent
        color: Config.StaticData.palette.secondary.col700
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        Layout.alignment: Qt.AlignTop
        spacing: 0

        Rectangle {
            id: topBar
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 38
            Layout.alignment: Qt.AlignTop
            color: Config.StaticData.palette.secondary.col700

            RowLayout {
                id: topBarColumns
                anchors.fill: parent
                spacing: 8

                VectorImage {
                    id: topBarMenuIcon
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    Layout.margins: 6
                    source: "resources/threeLines.svg"
                    visible: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: menuArea.containsMouse
                            ? Config.StaticData.palette.secondary.col100
                            : Config.StaticData.palette.secondary.col200
                    }

                    MouseArea {
                        id: menuArea
                        anchors.fill: topBarMenuIcon
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: {
                            if (mainStackView.depth > 1)
                                mainStackView.pop();
                            else {
                                topBarMenuIcon.source = !sideMenu.visible ? "resources/caretLeft.svg" : "resources/threeLines.svg";
                                sideMenu.visible = !sideMenu.visible;
                            }
                        }
                    }
                }

                Item {
                    id: topBarMenuSpace
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 2
                }

                VectorImage {
                    id: topBarSettingsIcon
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.margins: 6
                    source: "resources/settings.svg"
                    visible: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: settingsArea.containsMouse
                            ? Config.StaticData.palette.secondary.col100
                            : Config.StaticData.palette.secondary.col200
                    }

                    MouseArea {
                        id: settingsArea
                        anchors.fill: topBarSettingsIcon
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: {
                            mainStackView.push("pages/SettingsPage.qml");
                            sideMenu.visible = false;
                        }

                    }
                }
            }
        }

        StackView {
            id: mainStackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            initialItem: PreLoader {}

            replaceEnter: Transition {
                YAnimator {
                    from: (mainStackView.mirrored ? -1 : 1) * -mainStackView.height
                    to: 0
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }

            replaceExit: Transition {
                YAnimator {
                    from: 0
                    to: (mainStackView.mirrored ? -1 : 1) * mainStackView.height
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }

            onCurrentItemChanged: {
                console.log("[NAV] Stack depth:", depth, "| currentItem:", currentItem ? (currentItem.objectName || currentItem.toString()) : "null")
                var isLobby = (currentItem && currentItem.objectName === "lobbyPage");
                if (depth <= 1) {
                    topBarSettingsIcon.visible = true;
                    topBarMenuIcon.source = sideMenu.visible ? "resources/caretLeft.svg" : "resources/threeLines.svg";
                } else if (isLobby) {
                    topBarSettingsIcon.visible = true;
                    topBarMenuIcon.source = "resources/doorExit.svg";
                } else {
                    topBarSettingsIcon.visible = true;
                    topBarMenuIcon.source = "resources/doorExit.svg";
                }
            }
        }
    }

    // ── Tastenkürzel ──────────────────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (mainStackView.depth > 1) {
                mainStackView.pop()
            } else if (sideMenu.visible) {
                sideMenu.visible = false
                topBarMenuIcon.source = "resources/threeLines.svg"
            }
        }
    }

    Shortcut {
        sequence: StandardKey.Back
        onActivated: {
            if (mainStackView.depth > 1)
                mainStackView.pop()
        }
    }

    Shortcut {
        sequence: "Alt+S"
        onActivated: {
            if (mainStackView.depth === 1) {
                mainStackView.push("pages/SettingsPage.qml")
                sideMenu.visible = false
            }
        }
    }

    SideMenu {}

    Connections {
        target: mainStackView
        Component.onDestruction: topBarMenuIcon.source = mainStackView.depth === 1 ? "resources/threeLines.svg" : "resources/doorExit.svg"
    }
}
