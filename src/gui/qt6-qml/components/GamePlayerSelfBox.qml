import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import "../config" as Config

Rectangle {
    id: root

    property bool up: false
    property int maxAvatarSize: 60

    // Eigene Spielerdaten aus GameTable (Sitz 0 = Human Player)
    readonly property var selfData: (typeof GameTable !== "undefined" && GameTable && GameTable.players.length > 0)
        ? GameTable.players[0] : null

    readonly property int card0: selfData && selfData.card0 !== undefined ? selfData.card0 : -1
    readonly property int card1: selfData && selfData.card1 !== undefined ? selfData.card1 : -1
    readonly property bool isMyTurn: selfData ? selfData.myTurn : false
    readonly property bool isWinner: typeof GameTable !== "undefined" && GameTable && GameTable.winnerSeatId === 0
    readonly property int button: selfData && selfData.button !== undefined ? selfData.button : 0
    readonly property int bet: selfData && selfData.bet !== undefined ? selfData.bet : 0
    // Ich habe gefoldet → eigene Karten durchscheinend (wie im Qt-Widgets-Client)
    readonly property bool folded: selfData && selfData.folded !== undefined ? selfData.folded : false

    color: "transparent"

    // Hintergrund
    Rectangle {
        anchors.fill: parent
        color: Config.StaticData.palette.secondary.col600
        opacity: 0.8
        radius: 5
    }

    // Highlight: weicher Außen-Glow wenn ich am Zug bin
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        color: "transparent"
        radius: 6
        border.color: root.isMyTurn ? "#99FFD54A" : "transparent"
        border.width: root.isMyTurn ? 1 : 0
        z: 10

        layer.enabled: root.isMyTurn
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#FFD700"
            shadowOpacity: 0.75
            shadowBlur: 1.0
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }
    }

    // ── Karten – zentriert über der Infozeile ────────────────────────────────
    // Horizontale Abstände einheitlich: linker Außenrand = Abstand Avatar↔Karten
    // = rechter Außenrand = hMargin.
    readonly property int hMargin: 6
    // Vertikale Abstände einheitlich: oberer Außenrand = Abstand Karten↔Text
    // = unterer Außenrand = vMargin.
    readonly property int vMargin: 4

    Item {
        id: cardsArea
        anchors.top: parent.top
        anchors.topMargin: root.vMargin
        anchors.bottom: bottomBar.top
        anchors.bottomMargin: root.vMargin
        anchors.left: parent.left
        anchors.leftMargin: root.hMargin
        anchors.right: parent.right
        anchors.rightMargin: root.hMargin

        readonly property int cardH: height
        // Original-Seitenverhältnis der Karten (SVG-viewBox 120×168, wie der
        // Community-Cards-Bereich) → Höhe beibehalten, Breite ergibt sich daraus.
        readonly property int cardW: Math.round(cardH * 120 / 168)
        readonly property int avatarSize: Math.min(cardH, root.maxAvatarSize)
        readonly property int spacing: 4
        readonly property int gap: root.hMargin
        readonly property int cardsW: cardW * 2 + spacing
        readonly property int totalW: avatarSize + gap + cardsW
        readonly property int sx: (width - totalW) / 2

        Rectangle {
            id: selfAvatarBox
            x: cardsArea.sx
            y: (parent.height - height) / 2
            width: cardsArea.avatarSize
            height: cardsArea.avatarSize

            Rectangle {
                anchors.fill: parent
                border.width: 1
                border.color: Config.StaticData.palette.secondary.col200
                color: Config.StaticData.palette.secondary.col700
                opacity: 0.9
                radius: 2
            }

            Image {
                anchors.fill: parent
                anchors.margins: 1
                fillMode: Image.PreserveAspectFit
                source: "qrc:resources/pokerth.svg"
            }
        }

        Rectangle {
            x: cardsArea.sx + cardsArea.avatarSize + cardsArea.gap
            y: (parent.height - height) / 2
            width: cardsArea.cardW
            height: cardsArea.cardH
            color: "transparent"
            opacity: root.folded ? 0.3 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
            CardImage { anchors.fill: parent; cardIndex: root.card0 }
        }

        Rectangle {
            x: cardsArea.sx + cardsArea.avatarSize + cardsArea.gap + cardsArea.cardW + cardsArea.spacing
            y: (parent.height - height) / 2
            width: cardsArea.cardW
            height: cardsArea.cardH
            color: "transparent"
            opacity: root.folded ? 0.3 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
            CardImage { anchors.fill: parent; cardIndex: root.card1 }
        }
    }

    // ── Name + Stack – unterer Außenrand = oberer Außenrand (cardsArea.topMargin) ──
    Row {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.vMargin
        anchors.left: parent.left
        anchors.leftMargin: root.hMargin
        anchors.right: parent.right
        anchors.rightMargin: root.hMargin
        height: 16
        spacing: 5

        Text {
            id: playerName
            width: (parent.width - parent.spacing) / 2
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignLeft
            color: Config.StaticData.palette.secondary.col100
            font.family: Config.StaticData.loadedFont.font.family
            font.pixelSize: 12
            font.bold: true
            elide: Text.ElideRight
            text: root.selfData && root.selfData.name !== "" ? root.selfData.name : qsTr("Du")
        }

        Text {
            id: playerStack
            width: (parent.width - parent.spacing) / 2
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            color: Config.Theme.colorAccent
            font.family: Config.StaticData.loadedFont.font.family
            font.pixelSize: 12
            font.bold: true
            text: root.selfData ? "$" + root.selfData.stack : "$0"
        }
    }

    // Einsatz (Chip + Betrag) + Dealer/Small-/Big-Blind-Button – oberhalb der Box.
    // Button rechts neben dem Einsatz, beides zusammen zentriert.
    Item {
        id: betGroup
        visible: root.bet > 0 || root.button > 0
        z: 25

        readonly property int gap: 4
        readonly property real betW: root.bet > 0 ? betRow.width : 0
        readonly property real betH: root.bet > 0 ? betRow.height : 0
        readonly property real btnW: root.button > 0 ? buttonImg.width : 0
        readonly property real btnH: root.button > 0 ? buttonImg.height : 0
        readonly property real bothGap: (root.bet > 0 && root.button > 0) ? gap : 0

        width: betW + bothGap + btnW
        height: Math.max(betH, btnH)
        x: (parent.width - width) / 2
        y: -height - 2

        Row {
            id: betRow
            visible: root.bet > 0
            spacing: 2
            x: 0
            y: (betGroup.height - height) / 2

            Image {
                width: 16
                height: 16
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:resources/chipStack.svg"
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Config.StaticData.palette.secondary.col100
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 12
                font.bold: true
                text: "$" + root.bet
            }
        }

        Image {
            id: buttonImg
            visible: root.button > 0
            width: 26
            height: 26
            fillMode: Image.PreserveAspectFit
            x: betGroup.betW + betGroup.bothGap
            y: (betGroup.height - height) / 2
            source: root.button === 1 ? "../resources/tableDealerPuck.svg"
                  : root.button === 2 ? "../resources/tableSmallBlind.svg"
                  : root.button === 3 ? "../resources/tableBigBlind.svg"
                  : ""
        }
    }

    // Winner-Hervorhebung: goldener Rahmen + Badge
    Rectangle {
        anchors.fill: parent
        visible: root.isWinner
        color: "transparent"
        radius: 6
        border.color: "#FFD700"
        border.width: 3
        z: 19

        layer.enabled: root.isWinner
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#FFD700"
            shadowOpacity: 1.0
            shadowBlur: 1.0
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }
    }

    Rectangle {
        visible: root.isWinner
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 1
        width: winnerLabel.width + 14
        height: 18
        radius: 9
        color: "#0d3d0d"
        border.color: "#FFD700"
        border.width: 1
        z: 30

        Text {
            id: winnerLabel
            anchors.centerIn: parent
            text: qsTr("WINNER")
            color: "#FFD700"
            font.family: Config.StaticData.loadedFont.font.family
            font.pixelSize: 10
            font.bold: true
        }
    }
}
