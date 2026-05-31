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
    // Start-Auflösung = Phone-Landscape eines typischen Testgeräts (2316×1080).
    // Damit lässt sich das landscapeCompact-Layout am Desktop/AppImage testen,
    // ohne extra eine APK zu bauen. Beim Komponenten-Aufbau wird die Größe auf
    // den verfügbaren Bildschirm geclampt (Notebooks mit < 2316 px Breite würden
    // sonst Teile des Fensters außerhalb des sichtbaren Bereichs öffnen).
    width: 2316
    height: 1080
    // Initiale Portrait-Breite als untere Schranke – das Fenster darf nicht
    // schmaler werden als der Standard-Portrait-Modus, damit das Layout
    // (Slot-Spalten, Self-Box, Action-Buttons) immer komplett ins Bild passt.
    minimumWidth: 390
    minimumHeight: 600
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
        // Aspect-erhaltender Clamp auf den verfügbaren Bildschirm. 2316×1080
        // ist die Phone-Landscape-Testgröße (Aspect 2.144); auf Notebooks mit
        // 1920×1080 oder 2560×1440 würde das Fenster sonst entweder rausragen
        // oder sein Seitenverhältnis verlieren — beides hebelt den
        // landscapeCompact-Modus aus (Aspect-Schwelle 1.85).
        if (screen) {
            var maxW = screen.width  - 20
            var maxH = screen.height - 60   // Taskleiste/Titelbar
            var scale = Math.min(maxW / width, maxH / height, 1.0)
            if (scale < 1.0) {
                width  = Math.max(minimumWidth,  Math.floor(width  * scale))
                height = Math.max(minimumHeight, Math.floor(height * scale))
            }
        }
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

    function navigateBackFromTopBar() {
        if (mainStackView.depth <= 1)
            return false

        var current = mainStackView.currentItem

        // Warteraum: das Spiel sauber über den Server verlassen (wie der
        // "Leave Game"-Button). Der StackView wird durch onRemovedFromGame
        // gepoppt – hier NICHT direkt poppen.
        if (current && current.objectName === "gameWaitPage") {
            if (typeof Lobby !== "undefined" && Lobby)
                Lobby.leaveGame()
            return true
        }

        var isGamePage = current && current.objectName === "gamePage"
        var localGame = isGamePage
                        && (typeof GameTable !== "undefined")
                        && GameTable
                        && GameTable.isLocalGameRunning()

        // Laufendes Netzwerkspiel: serverseitig verlassen und zurück in die
        // LOBBY (nicht in den darunterliegenden Warteraum). Der StackView wird
        // durch onRemovedFromGame bis zur Lobby gepoppt – hier NICHT poppen.
        if (isGamePage && !localGame) {
            if (typeof Lobby !== "undefined" && Lobby)
                Lobby.leaveGame()
            return true
        }

        if (localGame)
            GameTable.endLocalGame()

        mainStackView.pop()
        if (localGame && mainStackView.depth > 1)
            mainStackView.pop()
        return true
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
                            if (!navigateBackFromTopBar()) {
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
                // console.log("[NAV] Stack depth:", depth, "| currentItem:", currentItem ? (currentItem.objectName || currentItem.toString()) : "null")
                var isLobby = (currentItem && currentItem.objectName === "lobbyPage");
                var isGame  = (currentItem && currentItem.objectName === "gamePage");
                var isGameWait = (currentItem && currentItem.objectName === "gameWaitPage");
                if (depth <= 1) {
                    topBarSettingsIcon.visible = true;
                    topBarMenuIcon.source = sideMenu.visible ? "resources/caretLeft.svg" : "resources/threeLines.svg";
                } else if (isLobby || isGame || isGameWait) {
                    // Lobby, Spiel UND Warteraum: Tür-Icon zum Verlassen.
                    topBarSettingsIcon.visible = true;
                    topBarMenuIcon.source = "resources/doorExit.svg";
                } else {
                    topBarSettingsIcon.visible = true;
                    topBarMenuIcon.source = "resources/caretLeft.svg";
                }
            }
        }
    }

    // ── Tastenkürzel ──────────────────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (!navigateBackFromTopBar() && sideMenu.visible) {
                sideMenu.visible = false
                topBarMenuIcon.source = "resources/threeLines.svg"
            }
        }
    }

    Shortcut {
        sequence: StandardKey.Back
        onActivated: {
            navigateBackFromTopBar()
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
        Component.onDestruction: topBarMenuIcon.source = mainStackView.depth === 1 ? "resources/threeLines.svg" : "resources/caretLeft.svg"
    }
}
