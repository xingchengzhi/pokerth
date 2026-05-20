import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.VectorImage

import "../config" as Config

GridLayout {
    id: root
    columns: 1
    rows: 2
    Layout.maximumHeight: 102

    property bool up: false
    property string yellow: "#E3C800"
    property int seatIndex: 0

    // Spielerdaten aus GameTable
    readonly property var seatData: (typeof GameTable !== "undefined" && GameTable && GameTable.players.length > seatIndex)
        ? GameTable.players[seatIndex] : null

    // Loch-Karten (face-up nur wenn vom Engine aufgedeckt, sonst Rückseite -1)
    readonly property int card0: seatData && seatData.card0 !== undefined ? seatData.card0 : -1
    readonly property int card1: seatData && seatData.card1 !== undefined ? seatData.card1 : -1

    // Am Zug?
    readonly property bool isMyTurn: seatData ? seatData.myTurn : false
    readonly property bool isActive: seatData ? seatData.active : false

    RowLayout {
        id: playerActions
        Layout.alignment: root.up ? Qt.AlignBottom : Qt.AlignTop
        Layout.row: root.up ? 1 : 2
        Layout.preferredHeight: 18 * gamePage.vScaleFactor
        Layout.maximumHeight: 26

        RowLayout {
            Layout.alignment: root.up ? Qt.AlignBottom : Qt.AlignTop

            Image {
                Layout.maximumWidth: 26
                Layout.preferredWidth: 18 * gamePage.vScaleFactor
                Layout.preferredHeight: 18 * gamePage.vScaleFactor
                Layout.maximumHeight: 26
                source: "qrc:resources/chipStack.svg"
                fillMode: Image.PreserveAspectFit
            }

            Text {
                id: playerBet
                horizontalAlignment: Text.AlignLeft
                leftPadding: 4
                bottomPadding: 3
                Layout.preferredHeight: 22
                color: Config.StaticData.palette.secondary.col100
                font.bold: true
                text: root.seatData ? "$" + root.seatData.bet : "$0"
            }
        }
    }

    Rectangle {
        id: playerBox
        Layout.row: root.up ? 2 : 1

        color: "transparent"
        Layout.minimumWidth: 112
        Layout.maximumWidth: 168
        Layout.minimumHeight: 76
        Layout.maximumHeight: 104
        Layout.preferredHeight: 76

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

        Row {
            id: topRow
            width: parent.width - 6
            height: parent.height - 26
            x: 6
            y: 4
            Rectangle {
                id: avatarRow
                width: parent.width / 12 * 5.1
                height: Math.min(parent.width / 12 * 5.1, topRow.height)

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

            // Karten: zentriert im verbleibenden Platz
            Item {
                id: cardsRow
                width: parent.width - avatarRow.width
                height: parent.height

                readonly property int cardW: 32
                readonly property int cardH: 46
                readonly property int cx: (width - cardW) / 2

                Rectangle {
                    id: card1Item
                    x: cardsRow.cx - 10
                    y: (parent.height - height) / 2
                    rotation: -6
                    width: cardsRow.cardW
                    height: cardsRow.cardH
                    color: "transparent"

                    VectorImage {
                        id: card1
                        anchors.fill: parent
                        fillMode: VectorImage.Stretch
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
                    x: cardsRow.cx + 8
                    y: (parent.height - height) / 2 + 2
                    rotation: 6
                    width: cardsRow.cardW
                    height: cardsRow.cardH
                    color: "transparent"

                    VectorImage {
                        id: card2
                        anchors.fill: parent
                        fillMode: VectorImage.Stretch
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
            y: parent.height - 22

            Text {
                id: playerName
                width: parent.width / 2
                horizontalAlignment: Text.AlignLeft
                color: Config.StaticData.palette.secondary.col100
                font.bold: true
                text: root.seatData && root.seatData.name !== "" ? root.seatData.name : "---"
            }

            Text {
                id: playerStack
                width: parent.width / 2
                horizontalAlignment: Text.AlignRight
                rightPadding: 6
                color: Config.Theme.colorAccent
                font.bold: true
                text: root.seatData && root.seatData.name !== "" ? "$" + root.seatData.stack : ""
            }
        }

        RowLayout {
            width: parent.width
            height: parent.height / 2
        }
    }
}
