import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects

import "../config" as Config
import "../components"

Rectangle {
    id: gameWaitPage
    objectName: "gameWaitPage"
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
    // Admin = entweder vom Server gemeldeter Admin-Status oder ich bin der
    // Spiel-Admin (Ersteller) laut Spiel-Info → Host kann starten.
    readonly property bool isAdmin: Lobby
        && (Lobby.isCurrentPlayerAdmin
            || (info.adminPlayerId !== undefined && info.adminPlayerId === Lobby.myPlayerId))
    readonly property bool isRanking: (info.gameType || 1) === 4
    readonly property bool canStart: isAdmin && !isRanking && players.length >= 2

    // NTF_NET_REMOVED_ON_REQUEST (socket_msg.h) – selbst angefordertes Verlassen
    readonly property int removedOnRequest: 202

    // Portrait-mode overlay state
    property bool showingPlayerList: false
    property int playerListCollapseResetCounter: 0

    function resetPlayerListDelegates() {
        playerListCollapseResetCounter += 1
        waitPagePlayerPanelList.currentIndex = -1
        waitPagePlayerSidebarList.currentIndex = -1
    }

    // Helfer analog zu LobbyPage
    function gameTypeIconSource(gameType) {
        if (gameType === 2) return "../resources/userSquare.svg"
        if (gameType === 3) return "../resources/users.svg"
        if (gameType === 4) return "../resources/chipStack.svg"
        return "../resources/user.svg"
    }

    // ── Chat-Status ────────────────────────────────────────────────────────
    property bool showEmojiPicker: false
    property var chatHistory: []
    property int chatHistoryIndex: 0

    function sendChatMessage() {
        if (typeof Lobby === "undefined" || !Lobby) return
        var msg = chatInput.text.trim()
        if (msg === "") return
        Lobby.sendChatMessage(msg)
        chatHistory.push(chatInput.text)
        if (chatHistory.length > 50) chatHistory.shift()
        chatHistoryIndex = 0
        chatInput.text = ""
    }

    function showChatHistory(idx) {
        if (idx > 0 && idx <= chatHistory.length)
            chatInput.text = chatHistory[chatHistory.length - idx]
        else
            chatInput.text = ""
        chatInput.cursorPosition = chatInput.text.length
    }

    Connections {
        target: Lobby
        function onRemovedFromGame(reason) {
            console.log("[NAV] GameWaitPage.onRemovedFromGame | reason:", reason, "| depth before:", mainStackView.depth, "| currentItem:", mainStackView.currentItem ? (mainStackView.currentItem.objectName || mainStackView.currentItem.toString()) : "null")
            if (reason === gameWaitPage.removedOnRequest) {
                var lobby = mainStackView.find(function(item) {
                    return item && item.objectName === "lobbyPage"
                })
                if (lobby)
                    mainStackView.pop(lobby)
                else
                    mainStackView.pop()
            } else {
                mainStackView.pop()
            }
            console.log("[NAV] GameWaitPage.onRemovedFromGame | depth after:", mainStackView.depth)
        }
        function onGameStarted() {
            console.log("[NAV] GameWaitPage.onGameStarted → pushing GamePage")
            mainStackView.push("GamePage.qml")
        }
        function onPlayerListFilterModeChanged() {
            if (playerListFilterCompact.currentIndex !== Lobby.playerListFilterMode)
                playerListFilterCompact.currentIndex = Lobby.playerListFilterMode
            if (playerListFilterWide.currentIndex !== Lobby.playerListFilterMode)
                playerListFilterWide.currentIndex = Lobby.playerListFilterMode
            gameWaitPage.resetPlayerListDelegates()
        }
    }

    // ── Compact: Player list panel (slides in from left) ─────────────────
    Rectangle {
        id: playerPanel
        width: gameWaitPage.width
        height: gameWaitPage.height
        y: 0
        x: gameWaitPage.showingPlayerList ? 0 : -width
        z: 3
        color: Config.StaticData.palette.secondary.col700
        visible: Config.Responsive.compact

        Behavior on x {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

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
                    color: closePanelArea.containsMouse
                           ? Config.StaticData.palette.secondary.col600
                           : "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: "../resources/close.svg"
                        sourceSize: Qt.size(28, 28)
                        smooth: true
                        antialiasing: true
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: Config.Theme.colorTextSecondary
                        }
                    }

                    MouseArea {
                        id: closePanelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: gameWaitPage.showingPlayerList = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Config.StaticData.palette.secondary.col500
            }

            TextField {
                id: panelSearchField
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
                id: waitPagePlayerPanelList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                property int expandedPlayerIndex: -1
                model: Lobby ? Lobby.playerListProxyModel : null

                delegate: PlayerListItem {
                    collapseResetCounter: gameWaitPage.playerListCollapseResetCounter
                    listView: waitPagePlayerPanelList
                    visible: (panelSearchField.text.length === 0 ||
                             displayName.toLowerCase().includes(panelSearchField.text.toLowerCase()))
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
                    if (Lobby && Lobby.playerListFilterMode !== currentIndex) {
                        Lobby.playerListFilterMode = currentIndex
                        gameWaitPage.resetPlayerListDelegates()
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

        // ── Header ────────────────────────────────────────────────────────
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

                Image {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: "../resources/users.svg"
                    sourceSize: Qt.size(48, 48)
                    smooth: true
                    antialiasing: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: Config.StaticData.palette.secondary.col200
                    }
                }

                MouseArea {
                    id: playerToggleArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: gameWaitPage.showingPlayerList = !gameWaitPage.showingPlayerList
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

        // ── Body: widescreen = sidebar + content; compact = content only ──
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Wide: player sidebar (left)
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
                        id: waitPagePlayerSidebarList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        property int expandedPlayerIndex: -1
                        model: Lobby ? Lobby.playerListProxyModel : null

                        delegate: PlayerListItem {
                            collapseResetCounter: gameWaitPage.playerListCollapseResetCounter
                            listView: waitPagePlayerSidebarList
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
                            if (Lobby && Lobby.playerListFilterMode !== currentIndex) {
                                Lobby.playerListFilterMode = currentIndex
                                gameWaitPage.resetPlayerListDelegates()
                            }
                        }
                    }
                }
            }

            // Main content column
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Config.Theme.spacing

                // ── Game details card ──────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.verticalStretchFactor: 2
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

                        // ── Spielerliste ─────────────────────────────────
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
                            Layout.minimumHeight: 0
                            clip: true
                            model: gameWaitPage.players
                            spacing: 4
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar {}

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

                // ── Game-Chat ──────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.verticalStretchFactor: gameWaitPage.showEmojiPicker ? 2 : 1
                    Layout.minimumHeight: 200
                    color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.2)
                    radius: 6

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Label {
                            text: qsTr("Lobby Chat")
                            font.family: Config.StaticData.loadedFont.font.family
                            font.bold: true
                            font.pixelSize: 13
                            color: Config.StaticData.palette.secondary.col200
                        }

                        ListView {
                            id: chatList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 0
                            clip: true
                            model: (typeof Lobby !== "undefined" && Lobby) ? Lobby.chatLog : []
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar {}
                            onCountChanged: positionViewAtEnd()
                            spacing: 3
                            delegate: Item {
                                required property var modelData
                                width: ListView.view.width
                                implicitHeight: bubble.height

                                Rectangle {
                                    id: bubble
                                    width: parent.width
                                    height: msgText.implicitHeight + 6
                                    radius: 8
                                    color: Config.Theme.withAlpha(Config.StaticData.palette.secondary.col600, 0.55)

                                    Text {
                                        id: msgText
                                        anchors {
                                            left: parent.left; right: parent.right; top: parent.top
                                            leftMargin: 8; rightMargin: 8; topMargin: 3
                                        }
                                        text: modelData
                                        textFormat: Text.RichText
                                        wrapMode: Text.WordWrap
                                        color: Config.StaticData.palette.secondary.col100
                                        font.family: Config.StaticData.loadedFont.font.family
                                        font.pixelSize: 12
                                        lineHeight: 1.0
                                        onLinkActivated: (link) => Qt.openUrlExternally(link)
                                    }
                                }
                            }
                        }

                        EmojiPicker {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 2 * 38 + 12 + 8
                            rows: 2
                            visible: gameWaitPage.showEmojiPicker
                            onPicked: (emoji) => {
                                chatInput.insert(chatInput.cursorPosition, emoji)
                                chatInput.forceActiveFocus()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Button {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                onClicked: gameWaitPage.showEmojiPicker = !gameWaitPage.showEmojiPicker
                                background: Rectangle {
                                    radius: 6
                                    color: gameWaitPage.showEmojiPicker
                                           ? Config.StaticData.palette.secondary.col500 : "transparent"
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                contentItem: Text {
                                    text: "🙂"
                                    font.family: Config.StaticData.emojiFamily
                                    font.pixelSize: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            TextField {
                                id: chatInput
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                enabled: !(Lobby && Lobby.isMyPlayerGuest)
                                placeholderText: (Lobby && Lobby.isMyPlayerGuest)
                                                 ? qsTr("Guests cannot chat")
                                                 : qsTr("Type your message...")
                                font.family: Config.StaticData.loadedFont.font.family
                                color: Config.StaticData.palette.secondary.col200
                                background: Rectangle {
                                    color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.5)
                                    radius: 3
                                }
                                placeholderTextColor: Qt.lighter(Config.StaticData.palette.secondary.col200, 1.5)
                                onAccepted: gameWaitPage.sendChatMessage()
                                Keys.onReturnPressed: gameWaitPage.sendChatMessage()
                                onTextEdited: gameWaitPage.chatHistoryIndex = 0
                                Keys.onUpPressed: (event) => {
                                    event.accepted = true
                                    if (gameWaitPage.chatHistoryIndex + 1 <= gameWaitPage.chatHistory.length)
                                        gameWaitPage.chatHistoryIndex++
                                    gameWaitPage.showChatHistory(gameWaitPage.chatHistoryIndex)
                                }
                                Keys.onDownPressed: (event) => {
                                    event.accepted = true
                                    if (gameWaitPage.chatHistoryIndex - 1 >= 0)
                                        gameWaitPage.chatHistoryIndex--
                                    gameWaitPage.showChatHistory(gameWaitPage.chatHistoryIndex)
                                }
                            }

                            Button {
                                Layout.minimumWidth: 44
                                Layout.preferredWidth: 44
                                Layout.maximumWidth: 44
                                Layout.preferredHeight: 36
                                Layout.maximumHeight: 44
                                enabled: !(Lobby && Lobby.isMyPlayerGuest) && chatInput.text.trim().length > 0
                                onClicked: gameWaitPage.sendChatMessage()
                                background: Item {}
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                contentItem: Image {
                                    width: 18
                                    height: 18
                                    anchors.centerIn: parent
                                    source: "../resources/send.svg"
                                    sourceSize: Qt.size(36, 36)
                                    smooth: true
                                    antialiasing: true
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        colorization: 1.0
                                        colorizationColor: Config.Theme.colorChatSend
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Aktionen ──────────────────────────────────────────────
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
    }
}
