import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import "../config" as Config

Rectangle {
    id: root

    property bool up: false

    // Eigene Spielerdaten aus GameTable (Sitz 0 = Human Player)
    readonly property var selfData: (typeof GameTable !== "undefined" && GameTable && GameTable.players.length > 0)
        ? GameTable.players[0] : null

    readonly property int card0: selfData && selfData.card0 !== undefined ? selfData.card0 : -1
    readonly property int card1: selfData && selfData.card1 !== undefined ? selfData.card1 : -1
    readonly property bool isMyTurn: selfData ? selfData.myTurn : false
    readonly property bool isWinner: typeof GameTable !== "undefined" && GameTable && GameTable.winnerSeatId === 0
    readonly property int button: selfData && selfData.button !== undefined ? selfData.button : 0
    readonly property int bet: selfData && selfData.bet !== undefined ? selfData.bet : 0

    color: "transparent"

    // Hintergrund
    Rectangle {
        anchors.fill: parent
        color: Config.StaticData.palette.secondary.col600
        opacity: 0.8
        radius: 5
    }

    // Highlight-Rahmen: leuchtet gelb wenn ich am Zug bin
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 6
        border.color: root.isMyTurn ? "#FFD700" : "transparent"
        border.width: root.isMyTurn ? 2 : 0
        z: 10

        layer.enabled: root.isMyTurn
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#FFD700"
            shadowOpacity: 0.9
            shadowBlur: 0.8
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }
    }

    // ── Karten – zentriert über der Infozeile ────────────────────────────────
    Item {
        id: cardsArea
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height - 30

        readonly property int cardW: 42
        readonly property int cardH: Math.min(60, height - 2)
        readonly property int overlap: 14
        readonly property int totalW: cardW * 2 - overlap
        readonly property int sx: (width - totalW) / 2

        Rectangle {
            x: cardsArea.sx
            y: (parent.height - height) / 2
            rotation: -6
            width: cardsArea.cardW
            height: cardsArea.cardH
            color: "transparent"
            CardImage { anchors.fill: parent; cardIndex: root.card0 }
        }

        Rectangle {
            x: cardsArea.sx + cardsArea.cardW - cardsArea.overlap
            y: (parent.height - height) / 2 + 2
            rotation: 6
            width: cardsArea.cardW
            height: cardsArea.cardH
            color: "transparent"
            CardImage { anchors.fill: parent; cardIndex: root.card1 }
        }
    }

    // ── Avatar + Name + Stack ─────────────────────────────────────────────────
    Row {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 5
        height: 30
        spacing: 5

        Rectangle {
            id: avatarBox
            width: 30
            height: 30
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                border.width: 1
                border.color: Config.StaticData.palette.secondary.col200
                color: Config.StaticData.palette.secondary.col600
                opacity: 0.5
                radius: 2
            }

            Image {
                anchors.fill: parent
                anchors.margins: 1
                fillMode: Image.PreserveAspectFit
                source: "qrc:resources/pokerth.svg"
            }
        }

        Text {
            id: playerName
            width: (parent.width - 30 - 5) / 2
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
            width: (parent.width - 30 - 5) / 2
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            color: Config.Theme.colorAccent
            font.family: Config.StaticData.loadedFont.font.family
            font.pixelSize: 12
            font.bold: true
            text: root.selfData ? "$" + root.selfData.stack : "$0"
        }
    }

    // Dealer / Small-Blind / Big-Blind Chip – linke obere Außenecke
    Image {
        visible: root.button > 0
        width: 20
        height: 20
        z: 25
        anchors.horizontalCenter: parent.left
        anchors.verticalCenter: parent.top
        anchors.verticalCenterOffset: parent.height / 2
        fillMode: Image.PreserveAspectFit
        source: root.button === 1 ? "../resources/tableDealerPuck.svg"
              : root.button === 2 ? "../resources/tableSmallBlind.svg"
              : root.button === 3 ? "../resources/tableBigBlind.svg"
              : ""
    }

    // Einsatz (Chip + Betrag) – oberhalb der Box (Richtung Tischmitte)
    Row {
        id: betRow
        visible: root.bet > 0
        spacing: 2
        z: 5
        x: (parent.width - width) / 2
        y: -height - 2

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
