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

    // Loch-Karten des menschlichen Spielers
    readonly property int card0: selfData && selfData.card0 !== undefined ? selfData.card0 : -1
    readonly property int card1: selfData && selfData.card1 !== undefined ? selfData.card1 : -1

    // Am Zug?
    readonly property bool isMyTurn: selfData ? selfData.myTurn : false

    color: "transparent"
    Layout.minimumWidth: 100
    Layout.maximumWidth: 160
    Layout.minimumHeight: 80
    Layout.maximumHeight: 104

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

    // ── Karten – zentriert über dem Avatar ───────────────────────────────────
    Item {
        id: cardsArea
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height - 26

        readonly property int cardW: 40
        readonly property int cardH: Math.min(58, height - 2)
        readonly property int overlap: 14
        readonly property int totalW: cardW * 2 - overlap
        readonly property int sx: (width - totalW) / 2

        Rectangle {
            id: card1Item
            x: cardsArea.sx
            y: (parent.height - height) / 2
            rotation: -6
            width: cardsArea.cardW
            height: cardsArea.cardH
            color: "transparent"

            CardImage {
                id: card1
                anchors.fill: parent
                cardIndex: root.card0
            }

            MultiEffect {
                source: card1
                anchors.fill: card1
                shadowEnabled: true
                shadowOpacity: 1
                shadowVerticalOffset: 2
                shadowHorizontalOffset: -1
                shadowBlur: 1
                autoPaddingEnabled: true
            }
        }

        Rectangle {
            id: card2Item
            x: cardsArea.sx + cardsArea.cardW - cardsArea.overlap
            y: (parent.height - height) / 2 + 2
            rotation: 6
            width: cardsArea.cardW
            height: cardsArea.cardH
            color: "transparent"

            CardImage {
                id: card2
                anchors.fill: parent
                cardIndex: root.card1
            }

            MultiEffect {
                source: card2
                anchors.fill: card2
                shadowEnabled: true
                shadowOpacity: 0.5
                shadowVerticalOffset: 2
                shadowHorizontalOffset: -1
                shadowBlur: 1
                autoPaddingEnabled: true
            }
        }
    }

    // ── Avatar + Name + Stack ─────────────────────────────────────────────────
    Row {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 5
        height: 20
        spacing: 4

        Image {
            id: avatar
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            fillMode: Image.PreserveAspectFit
            source: "qrc:resources/pokerth.svg"
        }

        Text {
            id: playerName
            width: (parent.width - 20 - 4) / 2
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignLeft
            color: Config.StaticData.palette.secondary.col100
            font.family: Config.StaticData.loadedFont.font.family
            font.pixelSize: 11
            font.bold: true
            elide: Text.ElideRight
            text: root.selfData && root.selfData.name !== "" ? root.selfData.name : qsTr("Du")
        }

        Text {
            id: playerStack
            width: (parent.width - 20 - 4) / 2
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            color: Config.Theme.colorAccent
            font.family: Config.StaticData.loadedFont.font.family
            font.pixelSize: 11
            font.bold: true
            text: root.selfData ? "$" + root.selfData.stack : "$0"
        }
    }
}
