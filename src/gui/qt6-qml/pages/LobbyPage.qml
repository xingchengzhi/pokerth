import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects

import "../config" as Config
import "../components"

Rectangle {
    id: lobbyPage
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    color: Config.StaticData.palette.secondary.col700

    // Mock data for development
    property int connectedPlayers: 42
    property int runningGames: 7
    property int openGames: 3

    // Portrait-mode overlay state
    property bool showingPlayerList: false
    property bool showingGameInfo: false
    property var selectedGame: null

    // ── Compact: Player list panel (slides in from left) ───────────────────
    Rectangle {
        id: playerPanel
        width: lobbyPage.width
        height: lobbyPage.height
        // Use lobbyPage.width/height (not mainWindow) so it always fills the StackView item
        y: 0
        x: lobbyPage.showingPlayerList ? 0 : -width
        z: 3
        color: Config.StaticData.palette.secondary.col700
        visible: Config.Responsive.compact

        Behavior on x {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        // Right border line
        Rectangle {
            anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
            width: 1
            color: Config.StaticData.palette.secondary.col500
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: qsTr("Players")
                    font.family: Config.StaticData.loadedFont.font.family
                    font.bold: true
                    font.pixelSize: 15
                    color: Config.StaticData.palette.secondary.col200
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 30
                    height: 30
                    radius: 4
                    color: closePlayerArea.containsMouse
                           ? Config.StaticData.palette.secondary.col600
                           : "transparent"

                    VectorImage {
                        id: closePlayerIcon
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: "../resources/close.svg"
                        MultiEffect {
                            source: closePlayerIcon
                            anchors.fill: closePlayerIcon
                            colorization: 1.0
                            colorizationColor: Config.StaticData.palette.secondary.col300
                        }
                    }

                    MouseArea {
                        id: closePlayerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: lobbyPage.showingPlayerList = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Config.StaticData.palette.secondary.col500
            }

            TextField {
                id: playerSearchField
                Layout.fillWidth: true
                placeholderText: qsTr("search for player ...")
                font.family: Config.StaticData.loadedFont.font.family
                color: Config.StaticData.palette.secondary.col200
                background: Rectangle {
                    color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.3)
                    radius: 3
                }
                placeholderTextColor: Qt.lighter(Config.StaticData.palette.secondary.col200, 1.5)
            }

            ListView {
                id: playerPanelList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: Lobby ? Lobby.playerListModel : null

                delegate: ItemDelegate {
                    width: playerPanelList.width
                    height: (playerSearchField.text.length === 0 ||
                             model.playerName.toLowerCase().includes(playerSearchField.text.toLowerCase())) ? 34 : 0
                    visible: height > 0

                    contentItem: Text {
                        text: model.playerName
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: model.isAdmin ? "#FFD700" : Config.StaticData.palette.secondary.col200
                        font.bold: model.isAdmin
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: parent.hovered
                               ? Qt.lighter(Config.StaticData.palette.secondary.col700, 1.2)
                               : "transparent"
                        radius: 3
                    }
                }
            }
        }
    }

    // ── Compact: Game info overlay (slides in from right) ──────────────────
    Rectangle {
        id: gameInfoOverlay
        width: lobbyPage.width
        height: lobbyPage.height
        y: 0
        x: lobbyPage.showingGameInfo ? 0 : lobbyPage.width
        z: 2
        color: lobbyPage.color
        visible: Config.Responsive.compact

        Behavior on x {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.Theme.margin
            spacing: Config.Theme.spacing

            // Header: back arrow + title
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

                    VectorImage {
                        id: backIcon
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: "../resources/caretLeft.svg"
                        MultiEffect {
                            source: backIcon
                            anchors.fill: backIcon
                            colorization: 1.0
                            colorizationColor: Config.StaticData.palette.secondary.col200
                        }
                    }

                    MouseArea {
                        id: backArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: lobbyPage.showingGameInfo = false
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
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Config.StaticData.palette.secondary.col500
            }

            // Game details card
            Rectangle {
                Layout.fillWidth: true
                height: 200
                color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.2)
                radius: 6

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Label {
                        text: lobbyPage.selectedGame
                              ? (lobbyPage.selectedGame.gameName || ("Game #" + lobbyPage.selectedGame.gameId))
                              : ""
                        font.family: Config.StaticData.loadedFont.font.family
                        font.bold: true
                        font.pixelSize: 15
                        color: Config.StaticData.palette.secondary.col100
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: lobbyPage.selectedGame
                              ? qsTr("Players: %1 / %2")
                                .arg(lobbyPage.selectedGame.playerCount || 0)
                                .arg(lobbyPage.selectedGame.maxPlayers || 10)
                              : ""
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: Config.StaticData.palette.secondary.col200
                    }

                    Label {
                        text: {
                            if (!lobbyPage.selectedGame) return ""
                            var cnt = lobbyPage.selectedGame.playerCount || 0
                            var max = lobbyPage.selectedGame.maxPlayers || 10
                            return cnt < max ? qsTr("Status: Open") : qsTr("Status: Full")
                        }
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: {
                            if (!lobbyPage.selectedGame) return Config.StaticData.palette.secondary.col300
                            var cnt = lobbyPage.selectedGame.playerCount || 0
                            var max = lobbyPage.selectedGame.maxPlayers || 10
                            return cnt < max ? "#4CAF50" : "#FFC107"
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // Join button
            CustomButton {
                text: qsTr("Join Game")
                Layout.fillWidth: true
                enabled: lobbyPage.selectedGame !== null
                onClicked: {
                    if (lobbyPage.selectedGame) {
                        Lobby.joinGame(lobbyPage.selectedGame.gameId)
                        lobbyPage.showingGameInfo = false
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ── Main layout ────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Config.Theme.margin
        spacing: Config.Theme.spacing

        // Filter row
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Compact: player list toggle button
            Rectangle {
                visible: Config.Responsive.compact
                implicitWidth: 38
                implicitHeight: 38
                radius: 5
                color: playerToggleArea.containsMouse
                       ? Config.StaticData.palette.secondary.col600
                       : Config.StaticData.palette.secondary.col700
                border.color: Config.StaticData.palette.secondary.col500
                border.width: 1

                VectorImage {
                    id: usersIcon
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: "../resources/users.svg"

                    MultiEffect {
                        source: usersIcon
                        anchors.fill: usersIcon
                        colorization: 1.0
                        colorizationColor: Config.StaticData.palette.secondary.col200
                    }
                }

                MouseArea {
                    id: playerToggleArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: lobbyPage.showingPlayerList = !lobbyPage.showingPlayerList
                }
            }

            // Wide: player search in filter bar
            TextField {
                id: searchPlayerField
                visible: !Config.Responsive.compact
                Layout.fillWidth: true
                placeholderText: qsTr("search for player ...")
                font.family: Config.StaticData.loadedFont.font.family
                color: Config.StaticData.palette.secondary.col200
                background: Rectangle {
                    color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.3)
                    radius: 3
                }
                placeholderTextColor: Qt.lighter(Config.StaticData.palette.secondary.col200, 1.5)
            }

            ComboBox {
                id: gameListFilter
                Layout.fillWidth: true
                font.family: Config.StaticData.loadedFont.font.family
                model: [
                    qsTr("No game list filter"),
                    qsTr("Show open games"),
                    qsTr("Show open & non-full games"),
                    qsTr("Show open & non-full & non-private games"),
                    qsTr("Show open & non-full & private games"),
                    qsTr("Show open & non-full & ranking games")
                ]
            }
        }

        // Main content
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Wide: Player list (hidden in compact — uses slide panel instead)
            Rectangle {
                visible: !Config.Responsive.compact
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.2)
                radius: 5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 5

                    Label {
                        text: qsTr("Available Players")
                        font.family: Config.StaticData.loadedFont.font.family
                        font.bold: true
                        color: Config.StaticData.palette.secondary.col200
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ListView {
                        id: playerListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: Lobby ? Lobby.playerListModel : null

                        delegate: ItemDelegate {
                            width: playerListView.width
                            height: 30

                            contentItem: Text {
                                text: model.playerName
                                font.family: Config.StaticData.loadedFont.font.family
                                font.pixelSize: 12
                                color: model.isAdmin ? "#FFD700" : Config.StaticData.palette.secondary.col200
                                font.bold: model.isAdmin
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: parent.hovered
                                       ? Qt.lighter(Config.StaticData.palette.secondary.col700, 1.2)
                                       : "transparent"
                                radius: 3
                            }
                        }
                    }
                }
            }

            // Center: Game list + (compact: chat below)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5

                // Game list: 2/3 in compact, full height in wide
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.verticalStretchFactor: Config.Responsive.compact ? 2 : 1
                    color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.2)
                    radius: 5

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5

                        // Game list
                        ListView {
                            id: gameListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: Lobby ? Lobby.gameListModel : null

                            delegate: ItemDelegate {
                                width: gameListView.width
                                height: 54

                                ColumnLayout {
                                    anchors {
                                        fill: parent
                                        leftMargin: 8; rightMargin: 8
                                        topMargin: 5; bottomMargin: 5
                                    }
                                    spacing: 3

                                    Text {
                                        text: model.gameName || ("Game #" + model.gameId)
                                        font.family: Config.StaticData.loadedFont.font.family
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: Config.StaticData.palette.secondary.col200
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 5

                                        Text {
                                            text: (model.playerCount || 0) + "/" + (model.maxPlayers || 10)
                                            font.family: Config.StaticData.loadedFont.font.family
                                            font.pixelSize: 12
                                            color: Config.StaticData.palette.secondary.col300
                                        }
                                        Text {
                                            text: "·"
                                            font.pixelSize: 12
                                            color: Config.StaticData.palette.secondary.col500
                                        }
                                        Text {
                                            text: (model.playerCount || 0) < (model.maxPlayers || 10)
                                                  ? qsTr("Open") : qsTr("Full")
                                            font.family: Config.StaticData.loadedFont.font.family
                                            font.pixelSize: 12
                                            color: (model.playerCount || 0) < (model.maxPlayers || 10)
                                                   ? "#4CAF50" : "#FFC107"
                                        }
                                        Text {
                                            text: "·"
                                            font.pixelSize: 12
                                            color: Config.StaticData.palette.secondary.col500
                                        }
                                        Text {
                                            text: qsTr("Blind: 10/20")
                                            font.family: Config.StaticData.loadedFont.font.family
                                            font.pixelSize: 12
                                            color: Config.StaticData.palette.secondary.col300
                                        }
                                        Item { Layout.fillWidth: true }
                                    }
                                }

                                background: Rectangle {
                                    color: parent.hovered
                                           ? Qt.lighter(Config.StaticData.palette.secondary.col700, 1.3)
                                           : "transparent"
                                    radius: 3
                                }

                                onClicked: {
                                    if (Config.Responsive.compact) {
                                        lobbyPage.selectedGame = model
                                        lobbyPage.showingGameInfo = true
                                    } else {
                                        Lobby.joinGame(model.gameId)
                                    }
                                }
                            }
                        }
                    }
                }

                // Compact: Lobby Chat (1/3 of height)
                Rectangle {
                    visible: Config.Responsive.compact
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.verticalStretchFactor: 1
                    color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.2)
                    radius: 5

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 4

                        Label {
                            text: qsTr("Lobby Chat")
                            font.family: Config.StaticData.loadedFont.font.family
                            font.bold: true
                            color: Config.StaticData.palette.secondary.col200
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                id: chatAreaCompact
                                readOnly: true
                                wrapMode: TextEdit.Wrap
                                font.family: Config.StaticData.loadedFont.font.family
                                font.pixelSize: 12
                                color: Config.StaticData.palette.secondary.col200
                                background: Rectangle { color: "transparent" }
                                text: qsTr("Welcome to PokerTH Lobby!\nChat messages will appear here...")
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            TextField {
                                id: chatInputCompact
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                placeholderText: qsTr("Type your message...")
                                font.family: Config.StaticData.loadedFont.font.family
                                color: Config.StaticData.palette.secondary.col200
                                background: Rectangle {
                                    color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.5)
                                    radius: 3
                                }
                                placeholderTextColor: Qt.lighter(Config.StaticData.palette.secondary.col200, 1.5)
                                onAccepted: sendChatMessage()
                            }

                            Button {
                                id: sendBtnCompact
                                Layout.minimumWidth: 44
                                Layout.preferredWidth: 44
                                Layout.maximumWidth: 44
                                Layout.preferredHeight: 36
                                Layout.maximumHeight: 44
                                onClicked: sendChatMessage()
                                contentItem: VectorImage {
                                    id: sendIconCompact
                                    width: 18
                                    height: 18
                                    anchors.centerIn: parent
                                    source: "../resources/send.svg"
                                    MultiEffect {
                                        source: sendIconCompact
                                        anchors.fill: sendIconCompact
                                        colorization: 1.0
                                        colorizationColor: Config.StaticData.palette.secondary.col200
                                    }
                                }
                            }
                        }
                    }
                }

                // Action buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        text: qsTr("Player: %1").arg(
                            Lobby && Lobby.myPlayerName !== "" ? Lobby.myPlayerName : "Guest")
                        font.family: Config.StaticData.loadedFont.font.family
                        font.bold: true
                        font.pixelSize: 14
                        color: Config.StaticData.palette.secondary.col100
                    }

                    Button {
                        text: qsTr("Create Game")
                        font.family: Config.StaticData.loadedFont.font.family
                        Layout.fillWidth: true
                        onClicked: Lobby.createGame()
                    }

                    Button {
                        text: qsTr("Join Game")
                        font.family: Config.StaticData.loadedFont.font.family
                        Layout.fillWidth: true
                        visible: !Config.Responsive.compact
                        enabled: gameListView.currentIndex >= 0
                        onClicked: {
                            if (gameListView.currentIndex >= 0) {
                                var item = Lobby.gameListModel.get(gameListView.currentIndex)
                                if (item) Lobby.joinGame(item.gameId)
                            }
                        }
                    }
                }
            }

            // Wide: right panel — Game Info + Chat
            ColumnLayout {
                visible: !Config.Responsive.compact
                Layout.preferredWidth: 250
                Layout.fillHeight: true
                spacing: 10

                // Game Info
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.2)
                    radius: 5

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5

                        Label {
                            text: qsTr("Game Info")
                            font.family: Config.StaticData.loadedFont.font.family
                            font.bold: true
                            font.pixelSize: 14
                            color: Config.StaticData.palette.secondary.col200
                        }

                        Label {
                            text: qsTr("Select a game to see details")
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: 12
                            color: Config.StaticData.palette.secondary.col300
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                // Lobby Chat
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.2)
                    radius: 5

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5

                        Label {
                            text: qsTr("Lobby Chat")
                            font.family: Config.StaticData.loadedFont.font.family
                            font.bold: true
                            color: Config.StaticData.palette.secondary.col200
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                id: chatArea
                                readOnly: true
                                wrapMode: TextEdit.Wrap
                                font.family: Config.StaticData.loadedFont.font.family
                                font.pixelSize: 12
                                color: Config.StaticData.palette.secondary.col200
                                background: Rectangle { color: "transparent" }
                                text: qsTr("Welcome to PokerTH Lobby!\nChat messages will appear here...")
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            TextField {
                                id: chatInput
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                placeholderText: qsTr("Type your message...")
                                font.family: Config.StaticData.loadedFont.font.family
                                color: Config.StaticData.palette.secondary.col200
                                background: Rectangle {
                                    color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.5)
                                    radius: 3
                                }
                                placeholderTextColor: Qt.lighter(Config.StaticData.palette.secondary.col200, 1.5)
                                onAccepted: sendChatMessage()
                                Keys.onReturnPressed: sendChatMessage()
                            }

                            Button {
                                id: sendBtnWide
                                Layout.minimumWidth: 44
                                Layout.preferredWidth: 44
                                Layout.maximumWidth: 44
                                Layout.preferredHeight: 36
                                Layout.maximumHeight: 44
                                onClicked: sendChatMessage()
                                contentItem: VectorImage {
                                    id: sendIconWide
                                    width: 18
                                    height: 18
                                    anchors.centerIn: parent
                                    source: "../resources/send.svg"
                                    MultiEffect {
                                        source: sendIconWide
                                        anchors.fill: sendIconWide
                                        colorization: 1.0
                                        colorizationColor: Config.StaticData.palette.secondary.col200
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Status bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Compact: eine Zeile mit Kurzform + elide
            Label {
                visible: Config.Responsive.compact
                Layout.fillWidth: true
                text: qsTr("%1 players · %2 running · %3 open")
                      .arg(connectedPlayers).arg(runningGames).arg(openGames)
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 12
                color: Config.StaticData.palette.secondary.col300
                elide: Text.ElideRight
            }

            // Wide: einzelne Labels
            Label {
                visible: !Config.Responsive.compact
                text: qsTr("connected players: %1").arg(connectedPlayers)
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 12
                color: Config.StaticData.palette.secondary.col300
            }
            Label {
                visible: !Config.Responsive.compact
                text: " | " + qsTr("running games: %1").arg(runningGames)
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 12
                color: Config.StaticData.palette.secondary.col300
            }
            Label {
                visible: !Config.Responsive.compact
                text: " | " + qsTr("open games: %1").arg(openGames)
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 12
                color: Config.StaticData.palette.secondary.col300
            }

            Item { Layout.fillWidth: true }

            Label {
                text: qsTr("<a href='https://www.pokerth.net'>PokerTH.net</a>")
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 12
                color: Config.StaticData.palette.secondary.col300
                textFormat: Text.RichText
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }
    }

    // Chat handler: append to both wide and compact chat areas
    Connections {
        target: Lobby
        function onChatMessageReceived(playerName, message) {
            var ts = new Date().toLocaleTimeString(Qt.locale(), "HH:mm:ss")
            var line = "\n[" + ts + "] " + playerName + ": " + message
            chatArea.text += line
            chatAreaCompact.text += line
        }
    }

    function sendChatMessage() {
        var msg = Config.Responsive.compact ? chatInputCompact.text.trim()
                                            : chatInput.text.trim()
        if (msg !== "") {
            Lobby.sendChatMessage(msg)
            if (Config.Responsive.compact)
                chatInputCompact.text = ""
            else
                chatInput.text = ""
        }
    }

    // ── Preview / Demo sequence ────────────────────────────────────────────
    SequentialAnimation {
        id: previewSequence
        running: false

        // 1. Lobby sichtbar — kurz einatmen
        PauseAnimation { duration: 600 }

        // 2. Spielerliste einblenden (slide from left)
        ScriptAction { script: lobbyPage.showingPlayerList = true }
        PauseAnimation { duration: 1200 }

        // 3. Spielerliste schließen
        ScriptAction { script: lobbyPage.showingPlayerList = false }
        PauseAnimation { duration: 700 }

        // 4. Erstes Spiel selektieren + Game-Info einblenden (slide from right)
        ScriptAction {
            script: {
                var game = (typeof Lobby !== "undefined" && Lobby
                            && Lobby.gameListModel
                            && Lobby.gameListModel.rowCount() > 0)
                    ? Lobby.gameListModel.get(0)
                    : ({ gameName: "My Online Game", gameId: 1,
                         playerCount: 3, maxPlayers: 10 })
                lobbyPage.selectedGame = game
                lobbyPage.showingGameInfo  = true
            }
        }
        PauseAnimation { duration: 1500 }

        // 5. Game-Info schließen
        ScriptAction {
            script: {
                lobbyPage.showingGameInfo = false
                lobbyPage.selectedGame    = null
            }
        }
        PauseAnimation { duration: 500 }

        // 6. CUT — zurück zur vorherigen Seite
        ScriptAction { script: StackView.view.pop() }
    }

    Component.onCompleted: {
        console.log("LobbyPage loaded")
        console.log("My player name:", Lobby.myPlayerName)
        console.log("Player model count:", Lobby.playerListModel.rowCount())
        console.log("Game model count:", Lobby.gameListModel.rowCount())
    }
}
