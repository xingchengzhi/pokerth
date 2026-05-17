import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects

import "../config" as Config
import "../components"

Rectangle {
    id: lobbyPage
    objectName: "lobbyPage"
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    color: Config.StaticData.palette.secondary.col700

    // Mock data for development
    property int connectedPlayers: Lobby ? Lobby.playerListModel.count : 0
    property int runningGames: Lobby ? Lobby.gameListModel.runningCount : 0
    property int openGames: Lobby ? Lobby.gameListModel.openCount : 0

    // Portrait-mode overlay state
    property bool showingPlayerList: false
    property bool showingGameInfo: false
    property var selectedGame: null
    property int playerListCollapseResetCounter: 0

    readonly property int gameListRevision: Lobby ? Lobby.gameListRevision : 0
    readonly property var selectedGamePlayers: {
        var _playerRev = Lobby ? Lobby.playerListRevision : 0
        var _gameRev = gameListRevision
        var gid = selectedGame ? selectedGame.gameId : 0
        return (Lobby && gid) ? Lobby.gamePlayersInGame(gid) : []
    }

    function gameTypeText(gameType) {
        if (gameType === 2) return qsTr("Registered players only")
        if (gameType === 3) return qsTr("Invited players only")
        if (gameType === 4) return qsTr("Ranking game")
        return qsTr("Standard")
    }

    function gameTypeIconSource(gameType) {
        if (gameType === 2) return "../resources/userSquare.svg"
        if (gameType === 3) return "../resources/users.svg"
        if (gameType === 4) return "../resources/chipStack.svg"
        return "../resources/user.svg"
    }

    function gameStatusText(mode, count, maxPlayers) {
        if (mode === 2) return qsTr("Running")
        if (mode === 3) return qsTr("Closed")
        return count < maxPlayers ? qsTr("Open") : qsTr("Full")
    }

    function gameStatusColor(mode, count, maxPlayers) {
        if (mode === 2) return "#FF9800"
        if (mode === 3) return "#EF5350"
        return count < maxPlayers ? "#4CAF50" : "#FFC107"
    }

    function resetPlayerListDelegates() {
        playerListCollapseResetCounter += 1
        playerPanelList.currentIndex = -1
        playerListView.currentIndex = -1
    }

    function applyPlayerListFilter(mode) {
        if (!Lobby) {
            return
        }

        if (Lobby.playerListFilterMode !== mode) {
            Lobby.playerListFilterMode = mode
        }

        resetPlayerListDelegates()
    }

    Connections {
        target: Lobby

        function onPlayerListFilterModeChanged() {
            if (playerListFilterCompact.currentIndex !== Lobby.playerListFilterMode) {
                playerListFilterCompact.currentIndex = Lobby.playerListFilterMode
            }
            if (playerListFilterWide.currentIndex !== Lobby.playerListFilterMode) {
                playerListFilterWide.currentIndex = Lobby.playerListFilterMode
            }
            lobbyPage.resetPlayerListDelegates()
        }

        function onGameListFilterModeChanged() {
            if (gameListFilter.currentIndex !== Lobby.gameListFilterMode) {
                gameListFilter.currentIndex = Lobby.gameListFilterMode
            }
        }
    }

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
                model: Lobby ? Lobby.playerListProxyModel : null

                delegate: PlayerListItem {
                    collapseResetCounter: lobbyPage.playerListCollapseResetCounter
                    listView: playerPanelList
                    visible: (playerSearchField.text.length === 0 ||
                             displayName.toLowerCase().includes(playerSearchField.text.toLowerCase()))
                }
            }

            ComboBox {
                id: playerListFilterCompact
                Layout.fillWidth: true
                font.family: Config.StaticData.loadedFont.font.family
                model: [
                    qsTr("Sort alphabetically"),
                    qsTr("Sort by country"),
                    qsTr("Display idle players")
                ]
                currentIndex: Lobby ? Lobby.playerListFilterMode : 0
                onCurrentIndexChanged: {
                    lobbyPage.applyPlayerListFilter(currentIndex)
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
                Layout.fillHeight: true
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
                            var mode = lobbyPage.selectedGame.gameMode || 1
                            var cnt = lobbyPage.selectedGame.playerCount || 0
                            var max = lobbyPage.selectedGame.maxPlayers || 10
                            return qsTr("Status: %1").arg(lobbyPage.gameStatusText(mode, cnt, max))
                        }
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: {
                            if (!lobbyPage.selectedGame) return Config.StaticData.palette.secondary.col300
                            var mode = lobbyPage.selectedGame.gameMode || 1
                            var cnt = lobbyPage.selectedGame.playerCount || 0
                            var max = lobbyPage.selectedGame.maxPlayers || 10
                            return lobbyPage.gameStatusColor(mode, cnt, max)
                        }
                    }

                    RowLayout {
                        visible: lobbyPage.selectedGame !== null
                        Layout.fillWidth: true
                        spacing: 6

                        VectorImage {
                            id: compactGameTypeIcon
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            source: lobbyPage.gameTypeIconSource((lobbyPage.selectedGame && lobbyPage.selectedGame.gameType) || 1)

                            MultiEffect {
                                source: compactGameTypeIcon
                                anchors.fill: compactGameTypeIcon
                                colorization: 1.0
                                colorizationColor: Config.StaticData.palette.secondary.col300
                            }
                        }

                        Label {
                            text: lobbyPage.selectedGame
                                  ? qsTr("Type: %1").arg(lobbyPage.gameTypeText(lobbyPage.selectedGame.gameType || 1))
                                  : ""
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: 13
                            color: Config.StaticData.palette.secondary.col200
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }

                    Label {
                        text: lobbyPage.selectedGame
                              ? qsTr("Small blind: %1").arg(lobbyPage.selectedGame.firstSmallBlind || 10)
                              : ""
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: Config.StaticData.palette.secondary.col200
                    }

                    Label {
                        text: lobbyPage.selectedGame
                              ? qsTr("Start cash: %1").arg(lobbyPage.selectedGame.startMoney || 0)
                              : ""
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: Config.StaticData.palette.secondary.col200
                    }

                    Label {
                        text: {
                            if (!lobbyPage.selectedGame) return ""
                            var mode = lobbyPage.selectedGame.raiseIntervalMode || 1
                            if (mode === 1) {
                                return qsTr("Blinds raise interval: %1 hands").arg(lobbyPage.selectedGame.raiseEveryHands || 0)
                            }
                            return qsTr("Blinds raise interval: %1 minutes").arg(lobbyPage.selectedGame.raiseEveryMinutes || 0)
                        }
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: Config.StaticData.palette.secondary.col200
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        text: lobbyPage.selectedGame
                              ? qsTr("Blinds raise mode: %1").arg((lobbyPage.selectedGame.raiseMode || 1) === 1
                                  ? qsTr("double blinds") : qsTr("manual blinds order"))
                              : ""
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: Config.StaticData.palette.secondary.col200
                        Layout.fillWidth: true
                    }

                    Label {
                        visible: lobbyPage.selectedGame && (lobbyPage.selectedGame.raiseMode || 1) !== 1 &&
                                 (lobbyPage.selectedGame.manualBlindsText || "").length > 0
                        text: lobbyPage.selectedGame
                              ? qsTr("Blinds list: %1").arg(lobbyPage.selectedGame.manualBlindsText || "")
                              : ""
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: Config.StaticData.palette.secondary.col200
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        text: lobbyPage.selectedGame
                              ? qsTr("Game timing: %1 sec (action)\n%2 sec (hand delay)")
                                .arg(lobbyPage.selectedGame.playerActionTimeoutSec || 0)
                                .arg(lobbyPage.selectedGame.delayBetweenHandsSec || 0)
                              : ""
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        color: Config.StaticData.palette.secondary.col200
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        visible: lobbyPage.selectedGame !== null
                        text: qsTr("Players in game (%1)").arg(lobbyPage.selectedGamePlayers.length)
                        font.family: Config.StaticData.loadedFont.font.family
                        font.bold: true
                        font.pixelSize: 13
                        color: Config.StaticData.palette.secondary.col100
                    }

                    ListView {
                        visible: lobbyPage.selectedGame !== null
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: lobbyPage.selectedGamePlayers
                        spacing: 4

                        delegate: Rectangle {
                            required property var modelData
                            width: ListView.view ? ListView.view.width : 0
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
                                    color: Qt.darker(Config.StaticData.palette.secondary.col600, 1.2)
                                    border.width: 1
                                    border.color: Config.StaticData.palette.secondary.col500
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
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        source: "../resources/user.svg"
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
                currentIndex: Lobby ? Lobby.gameListFilterMode : 0
                onCurrentIndexChanged: {
                    if (Lobby && Lobby.gameListFilterMode !== currentIndex) {
                        Lobby.gameListFilterMode = currentIndex
                    }
                }
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
                        model: Lobby ? Lobby.playerListProxyModel : null

                        delegate: PlayerListItem {
                            collapseResetCounter: lobbyPage.playerListCollapseResetCounter
                            listView: playerListView
                        }
                    }

                    ComboBox {
                        id: playerListFilterWide
                        Layout.fillWidth: true
                        font.family: Config.StaticData.loadedFont.font.family
                        model: [
                            qsTr("Sort alphabetically"),
                            qsTr("Sort by country"),
                            qsTr("Display idle players")
                        ]
                        currentIndex: Lobby ? Lobby.playerListFilterMode : 0
                        onCurrentIndexChanged: {
                            lobbyPage.applyPlayerListFilter(currentIndex)
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
                            model: Lobby ? Lobby.gameListProxyModel : null

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
                                            readonly property int gm: (model.gameMode || 1)
                                            readonly property int cnt: (model.playerCount || 0)
                                            readonly property int max: (model.maxPlayers || 10)
                                            text: {
                                                if (gm === 2) return qsTr("Running")
                                                if (gm === 3) return qsTr("Closed")
                                                return cnt < max ? qsTr("Open") : qsTr("Full")
                                            }
                                            font.family: Config.StaticData.loadedFont.font.family
                                            font.pixelSize: 12
                                            color: {
                                                if (gm === 2) return "#FF9800"
                                                if (gm === 3) return "#EF5350"
                                                return cnt < max ? "#4CAF50" : "#FFC107"
                                            }
                                        }
                                        Text {
                                            text: "·"
                                            font.pixelSize: 12
                                            color: Config.StaticData.palette.secondary.col500
                                        }
                                        Text {
                                            readonly property int sb: model.firstSmallBlind > 0 ? model.firstSmallBlind : 10
                                            text: qsTr("Blind: %1/%2").arg(sb).arg(sb * 2)
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
                                            text: model.isPrivate ? qsTr("Private") : qsTr("Public")
                                            font.family: Config.StaticData.loadedFont.font.family
                                            font.pixelSize: 12
                                            color: Config.StaticData.palette.secondary.col300
                                        }
                                        Text {
                                            text: "·"
                                            font.pixelSize: 12
                                            color: Config.StaticData.palette.secondary.col500
                                            visible: model.gameType === 4
                                        }
                                        Text {
                                            text: qsTr("Ranking")
                                            font.family: Config.StaticData.loadedFont.font.family
                                            font.pixelSize: 12
                                            color: Config.StaticData.palette.secondary.col300
                                            visible: model.gameType === 4
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
                                    gameListView.currentIndex = index
                                    lobbyPage.selectedGame = {
                                        gameId: model.gameId,
                                        gameName: model.gameName,
                                        playerCount: model.playerCount,
                                        maxPlayers: model.maxPlayers,
                                        gameMode: model.gameMode,
                                        isPrivate: model.isPrivate,
                                        gameType: model.gameType,
                                        firstSmallBlind: model.firstSmallBlind,
                                        startMoney: model.startMoney,
                                        raiseIntervalMode: model.raiseIntervalMode,
                                        raiseEveryHands: model.raiseEveryHands,
                                        raiseEveryMinutes: model.raiseEveryMinutes,
                                        raiseMode: model.raiseMode,
                                        manualBlindsText: model.manualBlindsText,
                                        playerActionTimeoutSec: model.playerActionTimeoutSec,
                                        delayBetweenHandsSec: model.delayBetweenHandsSec
                                    }

                                    if (Config.Responsive.compact) {
                                        lobbyPage.showingGameInfo = true
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
                        enabled: lobbyPage.selectedGame !== null
                        onClicked: {
                            if (lobbyPage.selectedGame) {
                                Lobby.joinGame(lobbyPage.selectedGame.gameId)
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

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            VectorImage {
                                id: wideGameTypeIcon
                                visible: lobbyPage.selectedGame !== null
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                source: lobbyPage.gameTypeIconSource((lobbyPage.selectedGame && lobbyPage.selectedGame.gameType) || 1)

                                MultiEffect {
                                    source: wideGameTypeIcon
                                    anchors.fill: wideGameTypeIcon
                                    colorization: 1.0
                                    colorizationColor: Config.StaticData.palette.secondary.col300
                                }
                            }

                            Label {
                                text: lobbyPage.selectedGame
                                      ? qsTr("Type: %1").arg(lobbyPage.gameTypeText(lobbyPage.selectedGame.gameType || 1))
                                      : qsTr("Select a game to see details")
                                font.family: Config.StaticData.loadedFont.font.family
                                font.pixelSize: 12
                                color: Config.StaticData.palette.secondary.col300
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        Label {
                            visible: lobbyPage.selectedGame !== null
                            text: lobbyPage.selectedGame
                                  ? qsTr("SB: %1 | Start cash: %2")
                                    .arg(lobbyPage.selectedGame.firstSmallBlind || 10)
                                    .arg(lobbyPage.selectedGame.startMoney || 0)
                                  : ""
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: 12
                            color: Config.StaticData.palette.secondary.col300
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Label {
                            visible: lobbyPage.selectedGame !== null
                            text: qsTr("Players in game (%1)").arg(lobbyPage.selectedGamePlayers.length)
                            font.family: Config.StaticData.loadedFont.font.family
                            font.bold: true
                            font.pixelSize: 12
                            color: Config.StaticData.palette.secondary.col200
                        }

                        ListView {
                            visible: lobbyPage.selectedGame !== null
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: lobbyPage.selectedGamePlayers
                            spacing: 4

                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view ? ListView.view.width : 0
                                height: 30
                                radius: 4
                                color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.1)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    spacing: 6

                                    Rectangle {
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        radius: 10
                                        color: Qt.darker(Config.StaticData.palette.secondary.col600, 1.2)
                                        border.width: 1
                                        border.color: Config.StaticData.palette.secondary.col500
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
                                            anchors.centerIn: parent
                                            width: 10
                                            height: 10
                                            source: "../resources/user.svg"
                                        }
                                    }

                                    Image {
                                        visible: (modelData.countryCode || "") !== ""
                                        source: (modelData.countryCode || "") !== ""
                                            ? "qrc:/resources/cflags/" + (modelData.countryCode || "").toLowerCase() + ".svg"
                                            : ""
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 12
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }

                                    Text {
                                        text: modelData.playerName || ""
                                        font.family: Config.StaticData.loadedFont.font.family
                                        font.pixelSize: 11
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

            Text {
                text: qsTr("PokerTH.net")
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 12
                color: (Config.StaticData.palette.primary && Config.StaticData.palette.primary.col400)
                       ? Config.StaticData.palette.primary.col400
                       : Config.StaticData.palette.secondary.col300
                font.underline: true

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var url = "https://www.pokerth.net"
                        var opened = false
                        if (Lobby) {
                            opened = Lobby.openExternalUrl(url)
                        } else {
                            opened = Qt.openUrlExternally(url)
                        }

                        if (!opened) {
                            console.warn("Failed to open footer URL:", url)
                        }
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
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
