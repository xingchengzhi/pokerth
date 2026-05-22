import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects

import "../components"
import "../config" as Config

Rectangle {
    id: gamePage
    objectName: "gamePage"
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    color: "transparent"

    property real hScaleFactor: 1
    property real vScaleFactor: 1
    property int initialWidth: 854
    property int initialHeight: 480
    property int currentWidth: mainWindow.width
    property int currentHeight: mainWindow.height

    onCurrentWidthChanged: {
        hScaleFactor = currentWidth / initialWidth;
    }

    onCurrentHeightChanged: {
        vScaleFactor = currentHeight / initialHeight;
    }

    Image {
        id: gameBackground
        source: "../resources/gameBackground.svg"
        fillMode: Image.PreserveAspectCrop
        width: parent.width
        height: parent.height
    }

    Image {
        id: gameTable
        visible: !Config.Responsive.compact
        anchors.centerIn: parent
        source: parent.width > 1920 ? "../resources/gameTableUHD.png" : "../resources/gameTableHD.png"
        fillMode: Image.PreserveAspectFit
        width: parent.width / 3 * 2
    }

    RowLayout {
        visible: !Config.Responsive.compact
        width: gamePage.width / 12 * 8
        x: gamePage.width / 12 * 2
        y: gamePage.height / 12

        GamePlayerBox {
            id: player5
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: 132 * gamePage.hScaleFactor
            Layout.preferredHeight: 70 * gamePage.vScaleFactor
            up: true
        }

        GamePlayerBox {
            id: player6
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 132 * gamePage.hScaleFactor
            Layout.preferredHeight: 70 * gamePage.vScaleFactor
            up: true
            betSide: "bottom"
        }

        GamePlayerBox {
            id: player7
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 132 * gamePage.hScaleFactor
            Layout.preferredHeight: 70 * gamePage.vScaleFactor
            up: true
        }
    }

    RowLayout {
        visible: !Config.Responsive.compact
        width: parent.width / 24 * 20
        x: parent.width / 24 * 2
        y: parent.height / 24 * 6

        GamePlayerBox {
            id: player4
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: 132 * gamePage.hScaleFactor
            Layout.preferredHeight: 70 * gamePage.vScaleFactor
            up: true
            betSide: "bottom"
        }

        GamePlayerBox {
            id: player8
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 132 * gamePage.hScaleFactor
            Layout.preferredHeight: 70 * gamePage.vScaleFactor
            up: true
        }
    }

    RowLayout {
        visible: !Config.Responsive.compact
        width: parent.width / 24 * 20
        x: parent.width / 24 * 2
        y: parent.height / 24 * 17 - 48

        GamePlayerBox {
            id: player3
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: 132 * gamePage.hScaleFactor
            Layout.preferredHeight: 70 * gamePage.vScaleFactor
            up: false
        }

        GamePlayerBox {
            id: player9
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 132 * gamePage.hScaleFactor
            Layout.preferredHeight: 70 * gamePage.vScaleFactor
            up: false
        }
    }

    RowLayout {
        visible: !Config.Responsive.compact
        width: parent.width / 12 * 7
        x: parent.width / 24 * 5
        y: parent.height / 24 * 21 - 64

        GamePlayerBox {
            id: player10
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: 132 * gamePage.hScaleFactor
            Layout.preferredHeight: 70 * gamePage.vScaleFactor
            up: false
        }

        GamePlayerSelfBox {
            id: player1
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 176 * gamePage.hScaleFactor
            Layout.preferredHeight: 104 * gamePage.vScaleFactor
            up: false
        }

        GamePlayerBox {
            id: player2
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 132 * gamePage.hScaleFactor
            Layout.preferredHeight: 70 * gamePage.vScaleFactor
            up: false
        }
    }

    RowLayout {
        id: gameDataBox
        visible: !Config.Responsive.compact
        width: gamePage.width / 12 * 4
        x: gamePage.width / 24 * 8
        y: gamePage.height / 12 * 4 + 8

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            Layout.margins: 0
            spacing: 0
            Text {
                id: gamePot
                Layout.preferredWidth: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Config.StaticData.palette.secondary.col200
                font.bold: true
                font.pointSize: 12 * gamePage.vScaleFactor
                text: qsTr("Pot")
            }

            Text {
                id: gamePotTotal
                Layout.preferredWidth: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Config.StaticData.palette.secondary.col200
                font.bold: true
                font.pointSize: 10 * gamePage.vScaleFactor
                text: qsTr("Total: $0")
            }

            Text {
                id: gamePotBets
                Layout.preferredWidth: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Config.StaticData.palette.secondary.col200
                font.bold: true
                font.pointSize: 10 * gamePage.vScaleFactor
                text: qsTr("Bets: $90")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.horizontalStretchFactor: 2
            color: "transparent"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            spacing: 0
            Text {
                id: gamePreflop
                Layout.preferredWidth: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Config.StaticData.palette.secondary.col200
                font.bold: true
                font.pointSize: 12 * gamePage.vScaleFactor
                text: qsTr("Preflop")
            }

            Text {
                id: gamePreflopGame
                Layout.preferredWidth: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Config.StaticData.palette.secondary.col200
                font.bold: true
                font.pointSize: 10 * gamePage.vScaleFactor
                text: qsTr("Game: 1")
            }

            Text {
                id: gamePreflopHand
                Layout.preferredWidth: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Config.StaticData.palette.secondary.col200
                font.bold: true
                font.pointSize: 10 * gamePage.vScaleFactor
                text: qsTr("Hand: 1")
            }
        }
    }

    RowLayout {
        id: cardHolderBox
        visible: !Config.Responsive.compact
        width: gamePage.width / 12 * 4
        x: gamePage.width / 24 * 8
        anchors.top: gameDataBox.bottom

        Rectangle {
            Layout.topMargin: 6 * gamePage.hScaleFactor
            Layout.preferredWidth: 52 * gamePage.hScaleFactor
            Layout.preferredHeight: 72 * gamePage.hScaleFactor
            color: "transparent"
            border.width: 2
            border.color: Config.StaticData.palette.secondary.col200
            radius: 8

            Rectangle {
                anchors.fill: parent
                color: Config.StaticData.palette.secondary.col300
                opacity: 0.4
            }

            CardImage {
                id: tableCard1
                x: -2 * gamePage.hScaleFactor
                y: 0
                width: (52 + 4) * gamePage.hScaleFactor
                height: (72) * gamePage.hScaleFactor
                cardIndex: {
                    var c = (typeof GameTable !== "undefined" && GameTable) ? GameTable.boardCards : null
                    return (c && c.length > 0) ? c[0] : -1
                }
            }
        }

        Rectangle {
            Layout.topMargin: 6 * gamePage.hScaleFactor
            Layout.preferredWidth: 52 * gamePage.hScaleFactor
            Layout.preferredHeight: 72 * gamePage.hScaleFactor
            Layout.fillHeight: true
            color: "transparent"
            border.width: 2
            border.color: Config.StaticData.palette.secondary.col200
            radius: 8

            Rectangle {
                anchors.fill: parent
                color: Config.StaticData.palette.secondary.col300
                opacity: 0.4
            }

            CardImage {
                id: tableCard2
                x: -2 * gamePage.hScaleFactor
                y: 0
                width: (52 + 4) * gamePage.hScaleFactor
                height: 72 * gamePage.hScaleFactor
                cardIndex: {
                    var c = (typeof GameTable !== "undefined" && GameTable) ? GameTable.boardCards : null
                    return (c && c.length > 1) ? c[1] : -1
                }
            }
        }

        Rectangle {
            Layout.topMargin: 6 * gamePage.hScaleFactor
            Layout.preferredWidth: 52 * gamePage.hScaleFactor
            Layout.preferredHeight: 72 * gamePage.hScaleFactor
            Layout.fillHeight: true
            color: "transparent"
            border.width: 2
            border.color: Config.StaticData.palette.secondary.col200
            radius: 8

            Rectangle {
                anchors.fill: parent
                color: Config.StaticData.palette.secondary.col300
                opacity: 0.4
            }

            CardImage {
                id: tableCard3
                x: -2 * gamePage.hScaleFactor
                y: 0
                width: (52 + 4) * gamePage.hScaleFactor
                height: 72 * gamePage.hScaleFactor
                cardIndex: {
                    var c = (typeof GameTable !== "undefined" && GameTable) ? GameTable.boardCards : null
                    return (c && c.length > 2) ? c[2] : -1
                }
            }
        }

        Rectangle {
            Layout.topMargin: 6 * gamePage.hScaleFactor
            Layout.preferredWidth: 52 * gamePage.hScaleFactor
            Layout.preferredHeight: 72 * gamePage.hScaleFactor
            Layout.fillHeight: true
            color: "transparent"
            border.width: 2
            border.color: Config.StaticData.palette.secondary.col200
            radius: 8

            Rectangle {
                anchors.fill: parent
                color: Config.StaticData.palette.secondary.col300
                opacity: 0.4
            }

            CardImage {
                id: tableCard4
                visible: (typeof GameTable !== "undefined" && GameTable) ? GameTable.boardCardCount >= 4 : false
                x: -2 * gamePage.hScaleFactor
                y: 0
                width: (52 + 4) * gamePage.hScaleFactor
                height: 72 * gamePage.hScaleFactor
                cardIndex: {
                    var c = (typeof GameTable !== "undefined" && GameTable) ? GameTable.boardCards : null
                    return (c && c.length > 3) ? c[3] : -1
                }
            }
        }

        Rectangle {
            Layout.topMargin: 6 * gamePage.hScaleFactor
            Layout.preferredWidth: 52 * gamePage.hScaleFactor
            Layout.preferredHeight: 72 * gamePage.hScaleFactor
            Layout.fillHeight: true
            color: "transparent"
            border.width: 2
            border.color: Config.StaticData.palette.secondary.col200
            radius: 8

            Rectangle {
                anchors.fill: parent
                color: Config.StaticData.palette.secondary.col300
                opacity: 0.4
            }

            CardImage {
                id: tableCard5
                visible: (typeof GameTable !== "undefined" && GameTable) ? GameTable.boardCardCount >= 5 : false
                x: -2 * gamePage.hScaleFactor
                y: 0
                width: (52 + 4) * gamePage.hScaleFactor
                height: 72 * gamePage.hScaleFactor
                cardIndex: {
                    var c = (typeof GameTable !== "undefined" && GameTable) ? GameTable.boardCards : null
                    return (c && c.length > 4) ? c[4] : -1
                }
            }
        }
    }

    // ── Portrait / compact layout ────────────────────────────────────────────
    // Optimiert für Hochformat (Smartphones). Aufbau:
    //   Status-Leiste (mit Tür-Icon) → Großer Tisch (alle Spieler überlagert) → Action-Leiste
    ColumnLayout {
        id: portraitLayout
        anchors.fill: parent
        visible: Config.Responsive.compact
        spacing: 0

        // 1. Status-Leiste: Spielphase | Pott | Hand-Nummer
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: Qt.rgba(0, 0, 0, 0.78)

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                spacing: 0

                Text {
                    text: GameTable ? GameTable.phaseText : qsTr("Preflop")
                    color: "#FFFFFF"
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 12
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Column {
                    spacing: -1
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: GameTable ? qsTr("Pot: $") + GameTable.pot : qsTr("Pot: $0")
                        color: "#99D500"
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: GameTable ? qsTr("Total: $") + GameTable.totalPot : qsTr("Total: $0")
                        color: "#7aa800"
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: GameTable ? qsTr("Hand ") + GameTable.handNumber : qsTr("Hand 1")
                    color: "#aaaaaa"
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 11
                }
            }
        }

        // 2. Tischzone: grüne Tischgrafik füllt gesamten Platz, alle Spieler überlagert
        Item {
            id: tableZone
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Grüne Tischgrafik füllt die gesamte Zone
            Image {
                anchors.fill: parent
                source: "../resources/tableGreen.png"
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            // Anzahl der besetzten Sitze
            readonly property int seatCount: {
                if (typeof GameTable === "undefined" || !GameTable) return 1
                var c = 0
                for (var i = 0; i < GameTable.players.length; i++)
                    if (GameTable.players[i].name !== "") c++
                return Math.max(c, 1)
            }

            // Feste Slot-Positionen (Mittelpunkt der Box als Anteil 0..1 der Zone).
            // 3 oben, je 2-3 an den Seiten – passt auch auf schmale Hochformate.
            readonly property var slotPos: ({
                "L_bottom": [0.18, 0.72],
                "L_lower":  [0.18, 0.59],
                "L_upper":  [0.18, 0.32],
                "TL":       [0.18, 0.19],
                "TC":       [0.50, 0.055],
                "TR":       [0.82, 0.19],
                "R_upper":  [0.82, 0.32],
                "R_lower":  [0.82, 0.59],
                "R_bottom": [0.82, 0.72]
            })

            // Slot-Reihenfolge je nach Gegnerzahl M – symmetrisch links/rechts verteilt,
            // damit unabhängig von der Spielerzahl Kreis-Symmetrie entsteht.
            readonly property var slotSeq: ({
                1: ["TC"],
                2: ["TL", "TR"],
                3: ["TL", "TC", "TR"],
                4: ["L_upper", "TL", "TR", "R_upper"],
                5: ["L_upper", "TL", "TC", "TR", "R_upper"],
                6: ["L_lower", "L_upper", "TL", "TR", "R_upper", "R_lower"],
                7: ["L_lower", "L_upper", "TL", "TC", "TR", "R_upper", "R_lower"],
                8: ["L_bottom", "L_lower", "L_upper", "TL", "TR", "R_upper", "R_lower", "R_bottom"],
                9: ["L_bottom", "L_lower", "L_upper", "TL", "TC", "TR", "R_upper", "R_lower", "R_bottom"]
            })

            // ── Gemeinschaftskarten + Pot – im oberen Tischbereich ───────────────
            Column {
                id: communityArea
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -tableZone.height * 0.045
                spacing: 6
                z: 0

                // Inline-Komponente für einen einzelnen Board-Card-Slot
                // Karten-Seitenverhältnis 120:168 (≈0,714) – Karte = Platzhalter (1:1)
                component CommunitySlot: Item {
                    property int boardIndex: 0
                    width: 46; height: 64

                    readonly property bool isDealt: {
                        var cnt = (typeof GameTable !== "undefined" && GameTable)
                                  ? GameTable.boardCardCount : 0
                        return boardIndex < cnt
                    }

                    // Platzhalter-Rahmen (immer sichtbar)
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: Qt.rgba(0, 0, 0, 0.30)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.38)
                    }

                    // Aufgedeckte Karte – mit Einblend-Animation
                    CardImage {
                        id: faceCard
                        anchors.fill: parent
                        opacity: 0
                        cardIndex: {
                            var cards = (typeof GameTable !== "undefined" && GameTable)
                                        ? GameTable.boardCards : null
                            return (cards && boardIndex < cards.length) ? cards[boardIndex] : -1
                        }
                    }

                    onIsDealtChanged: {
                        if (isDealt) {
                            cardReveal.start()
                        } else {
                            faceCard.opacity = 0
                        }
                    }

                    SequentialAnimation {
                        id: cardReveal
                        // Flop-Karten staffeln (0 ms, 120 ms, 240 ms); Turn/River sofort
                        PauseAnimation { duration: boardIndex < 3 ? boardIndex * 120 : 0 }
                        NumberAnimation {
                            target: faceCard
                            property: "opacity"
                            from: 0; to: 1
                            duration: 260
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                // 5 Slots: Flop (0-2) | Turn (3) | River (4)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3

                    CommunitySlot { boardIndex: 0 }
                    CommunitySlot { boardIndex: 1 }
                    CommunitySlot { boardIndex: 2 }

                    Item { width: 8; height: 1 }

                    CommunitySlot { boardIndex: 3 }

                    Item { width: 8; height: 1 }

                    CommunitySlot { boardIndex: 4 }
                }

                // Gewinner-Hand (z.B. "Full House") – nur während des Showdowns,
                // unterhalb der Gemeinschaftskarten (wie im Qt-Widgets-Client).
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: (typeof GameTable !== "undefined" && GameTable)
                             ? GameTable.winningHandText !== "" : false
                    width: winHandLabel.implicitWidth + 22
                    height: 22
                    radius: 11
                    color: Qt.rgba(0.05, 0.24, 0.05, 0.92)
                    border.color: "#FFD700"
                    border.width: 1

                    Text {
                        id: winHandLabel
                        anchors.centerIn: parent
                        text: (typeof GameTable !== "undefined" && GameTable)
                              ? GameTable.winningHandText : ""
                        color: "#FFD700"
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            // ── Gegner-Boxen: auf symmetrische Slots verteilt ────────────────────
            // Sitz 0 (Mensch) sitzt unten in der Mitte; die übrigen besetzten Sitze
            // werden gemäß slotSeq links/rechts ausgewogen verteilt.
            Repeater {
                model: 10
                delegate: Item {
                    id: seatSlot
                    required property int index
                    z: 1

                    readonly property var pdata: (typeof GameTable !== "undefined" && GameTable && GameTable.players.length > index)
                        ? GameTable.players[index] : null
                    readonly property bool occupied: pdata !== null && pdata.name !== ""

                    // Position dieses Sitzes unter den Gegnern (1-basiert; Sitz 0 = Mensch)
                    readonly property int oppOrder: {
                        if (typeof GameTable === "undefined" || !GameTable) return 0
                        var c = 0
                        for (var i = 1; i <= index && i < GameTable.players.length; i++)
                            if (GameTable.players[i].name !== "") c++
                        return c
                    }

                    readonly property int oppCount: tableZone.seatCount - 1
                    readonly property var seq: tableZone.slotSeq[oppCount] || []
                    readonly property string slotName:
                        (occupied && oppOrder >= 1 && oppOrder <= seq.length) ? seq[oppOrder - 1] : ""
                    readonly property var slot:
                        slotName !== "" ? tableZone.slotPos[slotName] : [0.5, 0.5]

                    visible: occupied && index !== 0 && slotName !== ""

                    // Inhalt füllt die Box ohne überschüssige Ränder; Karten im
                    // Original-Seitenverhältnis (2×27+3=57)
                    // (4 + Avatar 38 + 4 + Karten 57 + 4 = 107)
                    width: 107
                    height: 64
                    x: tableZone.width * slot[0] - width / 2
                    y: tableZone.height * slot[1] - height / 2

                    GamePlayerBox {
                        anchors.fill: parent
                        seatIndex: seatSlot.index
                        // Einsatz/Button zur Tischmitte zeigen lassen:
                        // linke Sitze rechts, rechte Sitze links, oben/unten-Mitte unten.
                        betSide: seatSlot.slot[0] < 0.45 ? "right"
                               : seatSlot.slot[0] > 0.55 ? "left"
                               : "bottom"
                    }
                }
            }

            // ── Eigene Box (Sitz 0): unten in der Mitte verankert ────────────────
            GamePlayerSelfBox {
                id: selfBox
                z: 1
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                // Schmaler: Inhalt füllt die Box ohne überschüssige Ränder
                // (6 + Avatar 54 + 6 + Karten [2×39+4=82] + 6 = 154)
                width: 154
                // Kompakter: keine überschüssige Höhe
                // (4 + Avatar/Karten 54 + 4 + Text 16 + 4 = 82)
                height: 82
                maxAvatarSize: 54
            }
        }

        // 3. Action-Leiste: Raise-Controls + Fold / Call / Raise
        Item {
            id: actionBar
            Layout.fillWidth: true
            // Höhe wächst dynamisch mit dem Inhalt
            Layout.preferredHeight: actionBarCol.implicitHeight

            // Aktuell vorbereiteter Raise-Betrag; kann auch vor dem eigenen Zug gesetzt werden
            property int raiseAmount: 0

            readonly property bool raiseAvailable: GameTable !== null
                                                   && GameTable.maxRaiseAmount > 0
                                                   && GameTable.minRaiseAmount > 0
            readonly property int raiseMinAmount: raiseAvailable ? GameTable.minRaiseAmount : 0
            readonly property int raiseMaxAmount: raiseAvailable ? GameTable.maxRaiseAmount : 0

            // Dynamische Button-Beschriftungen – analog zum Qt-Widgets-Client:
            //  • nichts zu callen  → "Check"      sonst → "Call $X"
            //  • Preflop oder schon gesetzt → "Raise $X"; postflop ohne Einsatz → "Bet $X"
            readonly property bool canCheck: GameTable !== null && GameTable.callAmount === 0
            readonly property bool isPreflop: GameTable !== null && GameTable.phaseText === "Preflop"
            readonly property string checkCallText: GameTable === null ? qsTr("Call")
                : (canCheck ? qsTr("Check") : qsTr("Call") + "\n$" + GameTable.callAmount)
            readonly property string betRaiseText: {
                if (GameTable === null) return qsTr("Raise")
                var word = (!isPreflop && canCheck) ? qsTr("Bet") : qsTr("Raise")
                return raiseAvailable ? (word + "\n$" + raiseAmount) : word
            }

            // ── Vorwahl (pre-selection): vor dem eigenen Zug eine Aktion vormerken ──
            property string preAction: ""        // "", "fold", "call", "raise", "allin"
            property int preCallAmount: -1        // callAmount zum Zeitpunkt der Vorwahl

            readonly property bool canAct: GameTable !== null && GameTable.canAct
            // Während der Vorwahl zeigt der Fold-Button bei freiem Check "Check / Fold"
            readonly property string foldText: (GameTable !== null && !GameTable.myTurn && canCheck)
                ? (qsTr("Check") + " / " + qsTr("Fold")) : qsTr("Fold")

            function fireAction(which) {
                if (GameTable === null) return
                if (which === "fold")       GameTable.fold()
                else if (which === "call")  GameTable.call()
                else if (which === "raise") GameTable.raise(raiseAmount)
                else if (which === "allin") GameTable.allIn()
            }

            // Vorgemerkte Aktion beim eigenen Zug ausführen.
            // Vorgemerktes "Fold" wird zu "Check", falls ein Check gratis möglich ist.
            function runPreAction(which) {
                if (which === "fold" && canCheck) GameTable.call()
                else fireAction(which)
            }

            function clickAction(which) {
                if (GameTable === null) return
                if (GameTable.myTurn) {
                    preAction = ""
                    fireAction(which)
                } else if (canAct) {
                    if (preAction === which) {
                        preAction = ""
                    } else {
                        preAction = which
                        preCallAmount = (which === "call") ? GameTable.callAmount : -1
                    }
                }
            }

            function raiseStepFor(maximum) {
                if (maximum <= 1000)
                    return 10
                if (maximum <= 10000)
                    return 50
                if (maximum <= 100000)
                    return 500
                return 5000
            }

            function roundedRaiseAmount(amount) {
                if (!raiseAvailable)
                    return 0
                if (amount >= raiseMaxAmount)
                    return raiseMaxAmount
                var step = raiseStepFor(raiseMaxAmount)
                return Math.floor(amount / step) * step
            }

            function clampRaiseAmount(amount) {
                if (!raiseAvailable)
                    return 0
                return Math.max(raiseMinAmount, Math.min(raiseMaxAmount, amount))
            }

            function syncRaiseAmount() {
                if (!raiseAvailable) {
                    raiseAmount = 0
                    return
                }
                if (raiseAmount <= 0)
                    raiseAmount = raiseMinAmount
                else
                    raiseAmount = clampRaiseAmount(roundedRaiseAmount(raiseAmount))
            }

            // Raise-Wert vorbereiten, Vorwahl ausführen bzw. bei Änderungen verwerfen
            Connections {
                target: GameTable
                function onMyTurnChanged() {
                    actionBar.syncRaiseAmount()
                    // Beim eigenen Zug die vorgemerkte Aktion ausführen
                    if (GameTable.myTurn && actionBar.preAction !== "") {
                        var a = actionBar.preAction
                        actionBar.preAction = ""
                        actionBar.runPreAction(a)
                    }
                }
                function onCallAmountChanged() {
                    // Sicherheit: vorgemerkter Call/Check verfällt, wenn sich der Call-Betrag ändert
                    if (actionBar.preAction === "call" && GameTable.callAmount !== actionBar.preCallAmount)
                        actionBar.preAction = ""
                    actionBar.syncRaiseAmount()
                }
                function onMinRaiseAmountChanged() {
                    if (actionBar.preAction === "raise" && !actionBar.raiseAvailable)
                        actionBar.preAction = ""
                    actionBar.syncRaiseAmount()
                }
                function onMaxRaiseAmountChanged() {
                    if (actionBar.preAction === "raise" && !actionBar.raiseAvailable)
                        actionBar.preAction = ""
                    actionBar.syncRaiseAmount()
                }
                function onCanActChanged() {
                    // Kann nicht mehr agieren (gefoldet/all-in) → Vorwahl löschen
                    if (!GameTable.canAct)
                        actionBar.preAction = ""
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.82)
            }

            Column {
                id: actionBarCol
                width: parent.width
                spacing: 0

                // ── Raise-Bereich: dauerhaft vorbereitbar, Aktion erst beim eigenen Zug ──
                Column {
                    id: raiseSection
                    width: parent.width
                    spacing: 4
                    topPadding: 5
                    bottomPadding: 3
                    leftPadding: 8
                    rightPadding: 8
                    visible: GameTable !== null
                    height: visible ? implicitHeight : 0
                    clip: true

                    // Zeile 1: Slider
                    Slider {
                        id: raiseSlider
                        width: parent.width - 16
                        height: 26
                        enabled: actionBar.raiseAvailable
                        opacity: enabled ? 1.0 : 0.45
                        from: actionBar.raiseMinAmount
                        to: actionBar.raiseAvailable ? Math.max(actionBar.raiseMinAmount, actionBar.raiseMaxAmount) : 1
                        stepSize: actionBar.raiseStepFor(actionBar.raiseMaxAmount)
                        value: actionBar.raiseAmount
                        onMoved: actionBar.raiseAmount = actionBar.clampRaiseAmount(actionBar.roundedRaiseAmount(value))

                        background: Rectangle {
                            x: raiseSlider.leftPadding
                            y: raiseSlider.topPadding + raiseSlider.availableHeight / 2 - height / 2
                            width: raiseSlider.availableWidth
                            height: 4
                            radius: 2
                            color: "#333333"
                            Rectangle {
                                width: raiseSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: "#4CAF50"
                            }
                        }
                        handle: Rectangle {
                            x: raiseSlider.leftPadding + raiseSlider.visualPosition * (raiseSlider.availableWidth - width)
                            y: raiseSlider.topPadding + raiseSlider.availableHeight / 2 - height / 2
                            width: 18; height: 18; radius: 9
                            color: raiseSlider.pressed ? "#80FF80" : "#4CAF50"
                            border.color: "#2a7a2a"
                            border.width: 1
                        }
                    }

                    // Zeile 2: Betrag-Eingabe + Pot-%-Buttons + All-In
                    RowLayout {
                        width: parent.width - 16
                        spacing: 4

                        // Betrag-Eingabe
                        Rectangle {
                            Layout.preferredWidth: 78
                            height: 28
                            radius: 5
                            color: actionBar.raiseAvailable ? "#1a2a1a" : "#171717"
                            border.color: actionBar.raiseAvailable ? "#4CAF50" : "#3a3a3a"
                            border.width: 1
                            TextInput {
                                id: raiseAmountInput
                                anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                                enabled: actionBar.raiseAvailable
                                text: actionBar.raiseAmount.toString()
                                color: enabled ? "#FFFFFF" : "#8a8a8a"
                                font.family: Config.StaticData.loadedFont.font.family
                                font.pixelSize: 13
                                font.bold: true
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator { bottom: 0; top: 9999999 }
                                onAccepted: {
                                    var v = parseInt(text)
                                    if (!isNaN(v) && GameTable) {
                                        actionBar.raiseAmount = actionBar.clampRaiseAmount(v)
                                    }
                                }
                                // Text bleibt synchron mit raiseAmount (von Slider/%-Buttons)
                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        text = actionBar.raiseAmount.toString()
                                    }
                                }
                                Connections {
                                    target: actionBar
                                    function onRaiseAmountChanged() {
                                        if (!raiseAmountInput.activeFocus)
                                            raiseAmountInput.text = actionBar.raiseAmount.toString()
                                    }
                                }
                            }
                        }

                        // Pot-Prozent-Buttons: 1/3 · 1/2 · Pot
                        Repeater {
                            model: [
                                { label: "1/3", frac: 1.0 / 3.0 },
                                { label: "1/2", frac: 0.5 },
                                { label: "Pot", frac: 1.0 }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                visible: SettingsManager
                                         ? SettingsManager.readConfigInt("ShowPotPercentButtons") !== 0
                                         : true
                                Layout.preferredWidth: visible ? 38 : 0
                                height: 28
                                radius: 5
                                enabled: actionBar.raiseAvailable
                                color: !enabled ? "#202020" : potBtnArea.containsPress ? "#2e7d32" : potBtnArea.containsMouse ? "#388e3c" : "#1b5e20"
                                border.color: enabled ? "#4CAF50" : "#3a3a3a"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: parent.enabled ? "#FFFFFF" : "#8a8a8a"
                                    font.family: Config.StaticData.loadedFont.font.family
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                MouseArea {
                                    id: potBtnArea
                                    anchors.fill: parent
                                    cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    hoverEnabled: parent.enabled
                                    enabled: parent.enabled
                                    onClicked: {
                                        if (!GameTable || !actionBar.raiseAvailable) return
                                        var tp = GameTable.totalPot
                                        var tgt = Math.round(tp * modelData.frac)
                                        actionBar.raiseAmount = actionBar.clampRaiseAmount(tgt)
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // All-In-Button (ebenfalls vorwählbar)
                        Rectangle {
                            id: allInBtn
                            readonly property bool preChecked: actionBar.preAction === "allin"
                            Layout.preferredWidth: 52
                            height: 28
                            radius: 5
                            opacity: actionBar.canAct ? 1.0 : 0.4
                            color: allInArea.containsPress ? "#7b1f1f" : allInArea.containsMouse ? "#9e2a2a" : "#5c1111"
                            border.color: allInBtn.preChecked ? "#FFD700" : "#ef5350"
                            border.width: allInBtn.preChecked ? 2 : 1
                            Text {
                                anchors.centerIn: parent
                                text: qsTr("All-In")
                                color: "#FFFFFF"
                                font.family: Config.StaticData.loadedFont.font.family
                                font.pixelSize: 12
                                font.bold: true
                            }
                            MouseArea {
                                id: allInArea
                                anchors.fill: parent
                                enabled: actionBar.canAct
                                cursorShape: actionBar.canAct ? Qt.PointingHandCursor : Qt.ArrowCursor
                                hoverEnabled: true
                                onClicked: actionBar.clickAction("allin")
                            }
                        }
                    }
                }

                // ── Aktions-Buttons: Fold / Check-Call / Bet-Raise ────────────────
                // Dynamische Beschriftung + Aktivierung wie im Qt-Widgets-Client.
                Item {
                    width: parent.width
                    height: 54

                    // Wiederverwendbarer Aktions-Button mit Verlauf, dynamischem Text und
                    // Vorwahl-Zustand (goldener Rahmen = vorgemerkt).
                    component ActionButton: Rectangle {
                        id: ab
                        property string actionKey: ""
                        property string label: ""
                        property color topColor: "#4080d8"
                        property color bottomColor: "#1a3d8b"
                        property color edgeColor: "#6aa0e8"
                        property bool armed: false   // klickbar: eigener Zug ODER Vorwahl möglich
                        readonly property bool myTurnNow: GameTable !== null && GameTable.myTurn
                        readonly property bool preChecked: ab.actionKey !== "" && actionBar.preAction === ab.actionKey

                        radius: 9
                        border.width: ab.preChecked ? 2 : 1
                        border.color: ab.preChecked ? "#FFD700" : (ab.armed ? edgeColor : "#3a3a3a")
                        opacity: !ab.armed ? 0.4 : ((ab.myTurnNow || ab.preChecked) ? 1.0 : 0.72)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: ab.armed ? ab.topColor : "#2b2b2b" }
                            GradientStop { position: 1.0; color: ab.armed ? ab.bottomColor : "#1c1c1c" }
                        }

                        Text {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: ab.label
                            color: "#F0F0F0"
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: 15
                            font.bold: true
                            lineHeight: 0.9
                        }

                        // kleiner "vorgemerkt"-Punkt oben rechts
                        Rectangle {
                            visible: ab.preChecked
                            anchors { top: parent.top; right: parent.right; margins: 4 }
                            width: 8; height: 8; radius: 4
                            color: "#FFD700"
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: ab.armed
                            cursorShape: ab.armed ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: actionBar.clickAction(ab.actionKey)
                        }
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 5; bottomMargin: 5 }
                        spacing: 8

                        ActionButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            actionKey: "fold"
                            label: actionBar.foldText
                            topColor: "#d94040"; bottomColor: "#8b1a1a"; edgeColor: "#e87070"
                            armed: actionBar.canAct
                        }

                        ActionButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            actionKey: "call"
                            label: actionBar.checkCallText
                            topColor: "#4080d8"; bottomColor: "#1a3d8b"; edgeColor: "#6aa0e8"
                            armed: actionBar.canAct
                        }

                        ActionButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            actionKey: "raise"
                            label: actionBar.betRaiseText
                            topColor: "#50b840"; bottomColor: "#1e6614"; edgeColor: "#7ad06a"
                            armed: actionBar.canAct && actionBar.raiseAvailable
                        }
                    }
                }
            }
        }
    }
}
