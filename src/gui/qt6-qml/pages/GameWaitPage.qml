import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects

import "../config" as Config
import "../components"

Rectangle {
    id: gameWaitPage
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: Config.StaticData.palette.secondary.col700

    // Refresh wenn sich Spielerliste oder Spielliste ändern
    readonly property int gameRev: Lobby ? Lobby.gameListRevision : 0
    readonly property int playerRev: Lobby ? Lobby.playerListRevision : 0

    readonly property var players: {
        var _g = gameRev; var _p = playerRev
        return (Lobby && Lobby.currentGameId) ? Lobby.gamePlayersInGame(Lobby.currentGameId) : []
    }
    readonly property var info: {
        var _g = gameRev
        return Lobby ? Lobby.currentGameInfo() : ({})
    }
    readonly property bool isAdmin: Lobby && Lobby.isCurrentPlayerAdmin
    readonly property bool isRanking: (info.gameType || 1) === 4
    readonly property bool canStart: isAdmin && !isRanking && players.length >= 2

    // Helfer analog zu LobbyPage
    function gameTypeIconSource(gameType) {
        if (gameType === 2) return "../resources/userSquare.svg"
        if (gameType === 3) return "../resources/users.svg"
        if (gameType === 4) return "../resources/chipStack.svg"
        return "../resources/user.svg"
    }

    Connections {
        target: Lobby
        function onRemovedFromGame() {
            console.log("[NAV] GameWaitPage.onRemovedFromGame | depth before:", mainStackView.depth, "| currentItem:", mainStackView.currentItem ? (mainStackView.currentItem.objectName || mainStackView.currentItem.toString()) : "null")
            mainStackView.pop()
            console.log("[NAV] GameWaitPage.onRemovedFromGame | depth after:", mainStackView.depth)
        }
        function onGameStarted() {
            console.log("[NAV] GameWaitPage.onGameStarted → pushing GamePage")
            mainStackView.push("GamePage.qml")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Config.Theme.margin
        spacing: Config.Theme.spacing

        // ── Header: Zurück + Titel ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                implicitWidth: 38
                implicitHeight: 38
                radius: 5
                color: backArea.containsMouse
                       ? Config.StaticData.palette.secondary.col600
                       : Config.StaticData.palette.secondary.col700
                border.color: Config.StaticData.palette.secondary.col500
                border.width: 1

                Image {
                    anchors.centerIn: parent
                    width: 18; height: 18
                    source: "../resources/caretLeft.svg"
                    sourceSize: Qt.size(36, 36)
                    smooth: true; antialiasing: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: Config.StaticData.palette.secondary.col200
                    }
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Lobby) Lobby.leaveGame()
                    }
                }
            }

            Label {
                text: qsTr("Game Info")
                font.family: Config.StaticData.loadedFont.font.family
                font.bold: true
                font.pixelSize: 16
                color: Config.StaticData.palette.secondary.col200
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Waiting for players …")
                color: Config.StaticData.palette.secondary.col300
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Config.StaticData.palette.secondary.col500
        }

        // ── Game details card ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.2)
            radius: 6

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Name
                Label {
                    text: info.name || ""
                    font.family: Config.StaticData.loadedFont.font.family
                    font.bold: true
                    font.pixelSize: 15
                    color: Config.StaticData.palette.secondary.col100
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                // Players X / max
                Label {
                    text: qsTr("Players: %1 / %2")
                          .arg(players.length)
                          .arg(info.maxPlayers || 0)
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 13
                    color: Config.StaticData.palette.secondary.col200
                }

                // Spieltyp + Icon
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Image {
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        source: gameWaitPage.gameTypeIconSource(info.gameType || 1)
                        sourceSize: Qt.size(28, 28)
                        smooth: true; antialiasing: true
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: Config.StaticData.palette.secondary.col300
                        }
                    }

                    Label {
                        text: qsTr("Type: %1").arg(Lobby ? Lobby.gameTypeText(info.gameType || 1) : "")
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: Config.StaticData.palette.secondary.col200
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                Label {
                    text: qsTr("Small blind: %1").arg(info.firstSmallBlind || 0)
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 13
                    color: Config.StaticData.palette.secondary.col200
                }

                Label {
                    text: qsTr("Start cash: %1").arg(info.startMoney || 0)
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 13
                    color: Config.StaticData.palette.secondary.col200
                }

                Label {
                    text: {
                        var mode = info.raiseIntervalMode || 1
                        if (mode === 1)
                            return qsTr("Blinds raise interval: %1 hands").arg(info.raiseEveryHands || 0)
                        return qsTr("Blinds raise interval: %1 minutes").arg(info.raiseEveryMinutes || 0)
                    }
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 13
                    color: Config.StaticData.palette.secondary.col200
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: qsTr("Blinds raise mode: %1").arg((info.raiseMode || 1) === 1
                          ? qsTr("double blinds") : qsTr("manual blinds order"))
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 13
                    color: Config.StaticData.palette.secondary.col200
                    Layout.fillWidth: true
                }

                Label {
                    text: qsTr("Game timing: %1 sec (action)\n%2 sec (hand delay)")
                          .arg(info.playerActionTimeoutSec || 0)
                          .arg(info.delayBetweenHandsSec || 0)
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 13
                    color: Config.StaticData.palette.secondary.col200
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                // ── Spielerliste ─────────────────────────────────────────
                Label {
                    text: qsTr("Players in game (%1)").arg(players.length)
                    font.family: Config.StaticData.loadedFont.font.family
                    font.bold: true
                    font.pixelSize: 13
                    color: Config.StaticData.palette.secondary.col100
                }

                ListView {
                    id: playerList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: gameWaitPage.players
                    spacing: 4

                    delegate: Rectangle {
                        required property var modelData
                        width: playerList.width
                        height: 32
                        radius: 4
                        color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.1)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 6

                            Rectangle {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                radius: 11
                                color: "transparent"
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    visible: (modelData.avatarUrl || "").length > 0
                                    source: modelData.avatarUrl || ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                }

                                VectorImage {
                                    visible: !((modelData.avatarUrl || "").length > 0)
                                    anchors.fill: parent
                                    source: "../resources/pokerth.svg"
                                }
                            }

                            Image {
                                visible: (modelData.countryCode || "") !== ""
                                source: (modelData.countryCode || "") !== ""
                                    ? "qrc:/resources/cflags/" + (modelData.countryCode || "").toLowerCase() + ".svg"
                                    : ""
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 14
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            Text {
                                text: modelData.playerName || ""
                                font.family: Config.StaticData.loadedFont.font.family
                                font.pixelSize: 12
                                color: (modelData.isAdmin === true)
                                    ? Config.StaticData.chartColor(3, true)
                                    : Config.StaticData.palette.secondary.col200
                                font.bold: modelData.isAdmin === true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        // ── Aktionen ─────────────────────────────────────────────────────
        // "Mit Computerspieler auffüllen" Checkbox – nur Admin + kein Ranking
        RowLayout {
            visible: gameWaitPage.isAdmin && !gameWaitPage.isRanking
            Layout.fillWidth: true
            spacing: 8

            CheckBox {
                id: fillCpuCheck
                text: qsTr("Fill up with computer players")
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 13
                checked: false
                contentItem: Text {
                    text: fillCpuCheck.text
                    font: fillCpuCheck.font
                    color: Config.StaticData.palette.secondary.col200
                    leftPadding: fillCpuCheck.indicator.width + fillCpuCheck.spacing
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            CustomButton {
                text: qsTr("Leave Game")
                Layout.fillWidth: true
                onClicked: {
                    if (Lobby) Lobby.leaveGame()
                }
            }

            CustomButton {
                visible: gameWaitPage.isAdmin && !gameWaitPage.isRanking
                enabled: gameWaitPage.canStart
                text: qsTr("Start Game")
                Layout.fillWidth: true
                onClicked: {
                    if (Lobby) Lobby.startGame(fillCpuCheck.checked)
                }
            }
        }
    }
}

