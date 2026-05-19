import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.VectorImage

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
    Layout.minimumWidth: 140
    Layout.maximumWidth: 196
    Layout.minimumHeight: 104
    Layout.maximumHeight: 132

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

    Row {
        id: topRow
        width: parent.width - 6
        height: parent.height / 2 - 6
        x: 6
        y: 6

        Rectangle {
            id: avatarRow
            width: parent.width / 12 * 5.1
            height: parent.width / 12 * 5.1

            Rectangle {
                anchors.fill: parent
                border.width: 1
                border.color: Config.StaticData.palette.secondary.col200
                color: Config.StaticData.palette.secondary.col600
                opacity: 0.5
            }

            Image {
                id: avatar
                width: parent.width
                fillMode: Image.PreserveAspectFit
                source: "qrc:resources/pokerth.svg"
            }
        }

        // Eigene Karten: größer und überlappend für bessere Lesbarkeit
        Item {
            id: cardsRow
            width: 88
            height: 72

            Rectangle {
                id: card1Item
                x: 0
                y: 0
                rotation: -6
                width: 46
                height: 69
                color: "transparent"

                VectorImage {
                    id: card1
                    anchors.fill: parent
                    fillMode: VectorImage.PreserveAspectFit
                    source: Config.StaticData.cardSource(root.card0)
                }

                MultiEffect {
                    source: card1
                    anchors.fill: card1
                    shadowEnabled: true
                    shadowOpacity: 1
                    shadowVerticalOffset: 1
                    shadowHorizontalOffset: -1
                    shadowBlur: 1
                    autoPaddingEnabled: true
                }
            }

            Rectangle {
                id: card2Item
                x: 34
                y: 2
                rotation: 6
                width: 46
                height: 69
                color: "transparent"

                VectorImage {
                    id: card2
                    anchors.fill: parent
                    fillMode: VectorImage.PreserveAspectFit
                    source: Config.StaticData.cardSource(root.card1)
                }

                MultiEffect {
                    source: card2
                    anchors.fill: card2
                    shadowEnabled: true
                    shadowOpacity: 0.5
                    shadowVerticalOffset: 1
                    shadowHorizontalOffset: -1
                    shadowBlur: 1
                    autoPaddingEnabled: true
                }
            }
        }
    }

    Row {
        id: playerNameRow
        width: parent.width - 8
        height: parent.height / 2 - 8
        x: 6
        y: parent.height - 26

        Text {
            id: playerName
            width: parent.width / 2
            horizontalAlignment: Text.AlignLeft
            color: Config.StaticData.palette.secondary.col100
            font.bold: true
            font.pointSize: 13
            text: root.selfData && root.selfData.name !== "" ? root.selfData.name : qsTr("Du")
        }

        Text {
            id: playerStack
            width: parent.width / 2
            horizontalAlignment: Text.AlignRight
            rightPadding: 6
            color: Config.Theme.colorAccent
            font.bold: true
            font.pointSize: 13
            text: root.selfData ? "$" + root.selfData.stack : "$0"
        }
    }

    RowLayout {
        width: parent.width
        height: parent.height / 2
    }
}
