import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import "../config" as Config

// Collapsible game list entry used in GameWaitPage (panel & sidebar).
// Required properties injected by the ListView delegate binding:
//   index, collapseResetCounter, listView, searchFilter, gameRevision
Item {
    id: gameItem

    required property int index
    required property int collapseResetCounter
    required property var listView
    required property string searchFilter
    required property int gameRevision

    // ── Model roles (Qt6 ListView auto-binds required properties to roles by name) ──
    required property var gameId
    required property var gameName
    required property var playerCount
    required property var maxPlayers
    required property var gameType
    required property var gameMode

    // ── Convenience aliases ───────────────────────────────────────────────
    readonly property int    itemGameId:      gameId      || 0
    readonly property string itemGameName:    gameName    || ""
    readonly property int    itemPlayerCount: playerCount || 0
    readonly property int    itemMaxPlayers:  maxPlayers  || 10
    readonly property int    itemGameType:    gameType    || 1
    readonly property int    itemGameMode:    gameMode    || 1

    // ── Players in this game (reactive on gameRevision) ───────────────────
    readonly property var gamePlayers: {
        var _r = gameRevision
        return (Lobby && itemGameId) ? (Lobby.gamePlayersInGame(itemGameId) || []) : []
    }

    // ── Filter ────────────────────────────────────────────────────────────
    readonly property bool matchesFilter: {
        var f = searchFilter.toLowerCase()
        return f.length === 0 || itemGameName.toLowerCase().includes(f)
    }

    // ── Collapse state ────────────────────────────────────────────────────
    property bool expanded: false

    onCollapseResetCounterChanged: { expanded = false }

    // ── Sizing ────────────────────────────────────────────────────────────
    width: listView.width
    height: matchesFilter ? (headerRect.height + (expanded ? playersCol.height : 0)) : 0
    visible: matchesFilter
    clip: true

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    // ── Header row ────────────────────────────────────────────────────────
    Rectangle {
        id: headerRect
        width: parent.width
        height: 52
        color: headerMouse.containsMouse
               ? Qt.lighter(Config.StaticData.palette.secondary.col700, 1.2)
               : "transparent"
        radius: 3

        RowLayout {
            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
            spacing: 5

            // Game type icon
            Image {
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                source: {
                    if (gameItem.itemGameType === 2) return "../resources/userSquare.svg"
                    if (gameItem.itemGameType === 3) return "../resources/users.svg"
                    if (gameItem.itemGameType === 4) return "../resources/chipStack.svg"
                    return "../resources/user.svg"
                }
                sourceSize: Qt.size(28, 28)
                smooth: true
                antialiasing: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: Config.StaticData.palette.secondary.col300
                }
            }

            // Name + status line
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: gameItem.itemGameName || ("Game #" + gameItem.itemGameId)
                    font.family: Config.StaticData.loadedFont.font.family
                    font.bold: true
                    font.pixelSize: 12
                    color: Config.StaticData.palette.secondary.col200
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: gameItem.itemPlayerCount + "/" + gameItem.itemMaxPlayers
                          + "  ·  "
                          + (Lobby ? Lobby.gameStatusText(gameItem.itemGameMode,
                                                          gameItem.itemPlayerCount,
                                                          gameItem.itemMaxPlayers) : "")
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 11
                    color: {
                        if (gameItem.itemGameMode === 2) return Config.Theme.colorStatusRunning
                        if (gameItem.itemGameMode === 3) return Config.Theme.colorStatusClosed
                        return gameItem.itemPlayerCount < gameItem.itemMaxPlayers
                            ? Config.Theme.colorStatusOpen
                            : Config.Theme.colorStatusFull
                    }
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            // Expand / collapse chevron
            Image {
                Layout.preferredWidth: 12
                Layout.preferredHeight: 12
                source: "../resources/caretLeft.svg"
                sourceSize: Qt.size(24, 24)
                rotation: gameItem.expanded ? 90 : -90
                smooth: true
                antialiasing: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: Config.StaticData.palette.secondary.col400
                }
                Behavior on rotation {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
            }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: gameItem.expanded = !gameItem.expanded
        }
    }

    // ── Expanded player sub-list ──────────────────────────────────────────
    Column {
        id: playersCol
        width: parent.width
        anchors.top: headerRect.bottom
        topPadding: 2
        bottomPadding: 6
        leftPadding: 22

        Repeater {
            model: gameItem.gamePlayers
            delegate: Text {
                width: playersCol.width - playersCol.leftPadding
                text: "· " + (modelData.playerName || modelData.name || "")
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 11
                color: Config.StaticData.palette.secondary.col300
                elide: Text.ElideRight
            }
        }
    }
}
