import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import "../config" as Config

Item {
    id: root

    property bool up: false
    property int seatIndex: 0
    // Seite, auf der Einsatz-Chip + Dealer/Blind-Button angezeigt werden:
    // "top" | "bottom" | "left" | "right". Default leitet sich aus 'up' ab.
    property string betSide: up ? "bottom" : "top"

    implicitWidth: 120
    implicitHeight: 64

    // Spielerdaten aus GameTable
    readonly property var seatData: (typeof GameTable !== "undefined" && GameTable && GameTable.players.length > seatIndex)
        ? GameTable.players[seatIndex] : null

    readonly property int card0: seatData && seatData.card0 !== undefined ? seatData.card0 : -1
    readonly property int card1: seatData && seatData.card1 !== undefined ? seatData.card1 : -1
    readonly property bool isMyTurn: seatData ? seatData.myTurn : false
    readonly property bool isActive: seatData ? seatData.active : false
    readonly property bool isWinner: typeof GameTable !== "undefined" && GameTable && GameTable.winnerSeatId === root.seatIndex
    readonly property int button: seatData && seatData.button !== undefined ? seatData.button : 0
    readonly property int bet: seatData && seatData.bet !== undefined ? seatData.bet : 0

    // Nur anzeigen wenn der Sitz besetzt ist
    visible: root.seatData !== null && root.seatData.name !== ""

    // ── Hauptbox ────────────────────────────────────────────────────────────────
    Rectangle {
        id: playerBox
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Config.StaticData.palette.secondary.col600
            opacity: 0.8
            radius: 5
        }

        // Highlight-Rahmen: leuchtet gelb wenn dieser Spieler am Zug ist
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

        // Avatar + Karten
        Row {
            id: topRow
            width: parent.width - 6
            height: parent.height - 26
            x: 4
            y: 4
            spacing: 2

            Rectangle {
                id: avatarBox
                width: parent.height
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    border.width: 1
                    border.color: Config.StaticData.palette.secondary.col200
                    color: Config.StaticData.palette.secondary.col700
                    opacity: 0.9
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:resources/pokerth.svg"
                }
            }

            Item {
                width: parent.width - avatarBox.width - 2
                height: parent.height

                readonly property int cardSpacing: 3
                readonly property int cardH: height
                readonly property int cardW: Math.round(cardH * 48 / 76)
                readonly property int totalW: cardW * 2 + cardSpacing
                readonly property int sx: (width - totalW) / 2

                Rectangle {
                    x: parent.sx
                    y: 0
                    width: parent.cardW
                    height: parent.cardH
                    color: "transparent"
                    CardImage { anchors.fill: parent; cardIndex: root.card0 }
                }

                Rectangle {
                    x: parent.sx + parent.cardW + parent.cardSpacing
                    y: 0
                    width: parent.cardW
                    height: parent.cardH
                    color: "transparent"
                    CardImage { anchors.fill: parent; cardIndex: root.card1 }
                }
            }
        }

        // Name + Stack
        Row {
            width: parent.width - 8
            height: 13
            x: 4
            y: parent.height - 18

            Text {
                width: parent.width / 2
                horizontalAlignment: Text.AlignLeft
                color: Config.StaticData.palette.secondary.col100
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 10
                font.bold: true
                elide: Text.ElideRight
                text: root.seatData && root.seatData.name !== "" ? root.seatData.name : "---"
            }

            Text {
                width: parent.width / 2
                horizontalAlignment: Text.AlignRight
                color: Config.Theme.colorAccent
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 10
                font.bold: true
                text: root.seatData && root.seatData.name !== "" ? "$" + root.seatData.stack : ""
            }
        }

        // Winner-Hervorhebung: goldener Rahmen – verdeckt die Karten NICHT
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
    }

    // WINNER-Badge oberhalb der Box
    Rectangle {
        visible: root.isWinner
        anchors.horizontalCenter: playerBox.horizontalCenter
        anchors.bottom: playerBox.top
        anchors.bottomMargin: 1
        width: winnerLabel.width + 12
        height: 16
        radius: 8
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
            font.pixelSize: 9
            font.bold: true
        }
    }

    // Dealer / Small-Blind / Big-Blind Chip – an der unteren Außenecke
    Image {
        visible: root.button > 0
        width: 18
        height: 18
        z: 25
        anchors.horizontalCenter: root.betSide === "right" ? playerBox.right : playerBox.left
        anchors.verticalCenter: playerBox.bottom
        fillMode: Image.PreserveAspectFit
        source: root.button === 1 ? "../resources/tableDealerPuck.svg"
              : root.button === 2 ? "../resources/tableSmallBlind.svg"
              : root.button === 3 ? "../resources/tableBigBlind.svg"
              : ""
    }

    // Einsatz (Chip + Betrag) – auf der zur Tischmitte zeigenden Seite
    Row {
        id: betRow
        visible: root.bet > 0
        spacing: 2
        z: 5

        x: root.betSide === "right" ? playerBox.width + 3
         : root.betSide === "left"  ? -width - 3
         : (playerBox.width - width) / 2
        y: root.betSide === "bottom" ? playerBox.height + 2
         : root.betSide === "top"    ? -height - 2
         : (playerBox.height - height) / 2

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
            font.pixelSize: 11
            font.bold: true
            text: "$" + root.bet
        }
    }
}
