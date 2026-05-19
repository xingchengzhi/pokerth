import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects

import "../components"
import "../config" as Config

Rectangle {
    id: gamePage
    anchors.fill: parent
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
            Layout.preferredWidth: 112 * gamePage.hScaleFactor
            Layout.preferredHeight: 78 * gamePage.vScaleFactor
            up: true
        }

        GamePlayerBox {
            id: player6
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 112 * gamePage.hScaleFactor
            Layout.preferredHeight: 78 * gamePage.vScaleFactor
            up: true
        }

        GamePlayerBox {
            id: player7
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 112 * gamePage.hScaleFactor
            Layout.preferredHeight: 78 * gamePage.vScaleFactor
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
            Layout.preferredWidth: 112 * gamePage.hScaleFactor
            Layout.preferredHeight: 78 * gamePage.vScaleFactor
            up: true
        }

        GamePlayerBox {
            id: player8
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 112 * gamePage.hScaleFactor
            Layout.preferredHeight: 78 * gamePage.vScaleFactor
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
            Layout.preferredWidth: 112 * gamePage.hScaleFactor
            Layout.preferredHeight: 78 * gamePage.vScaleFactor
            up: false
        }

        GamePlayerBox {
            id: player9
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 112 * gamePage.hScaleFactor
            Layout.preferredHeight: 78 * gamePage.vScaleFactor
            up: false
        }
    }

    RowLayout {
        visible: !Config.Responsive.compact
        width: parent.width / 12 * 6
        x: parent.width / 24 * 6
        y: parent.height / 24 * 21 - 64

        GamePlayerBox {
            id: player10
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: 112 * gamePage.hScaleFactor
            Layout.preferredHeight: 78 * gamePage.vScaleFactor
            up: false
        }

        GamePlayerSelfBox {
            id: player1
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 140 * gamePage.hScaleFactor
            Layout.preferredHeight: 104 * gamePage.vScaleFactor
            up: false
        }

        GamePlayerBox {
            id: player2
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 112 * gamePage.hScaleFactor
            Layout.preferredHeight: 78 * gamePage.vScaleFactor
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

            VectorImage {
                id: tableCard1
                x: -2 * gamePage.hScaleFactor
                y: 0
                width: (52 + 4) * gamePage.hScaleFactor
                height: (72) * gamePage.hScaleFactor
                fillMode: IconImage.Stretch
                source: "../resources/cardBackground.svg"
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

            VectorImage {
                id: tableCard2
                x: -2 * gamePage.hScaleFactor
                y: 0
                width: (52 + 4) * gamePage.hScaleFactor
                height: 72 * gamePage.hScaleFactor
                fillMode: IconImage.Stretch
                source: "../resources/cardBackground.svg"
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

            VectorImage {
                id: tableCard3
                x: -2 * gamePage.hScaleFactor
                y: 0
                width: (52 + 4) * gamePage.hScaleFactor
                height: 72 * gamePage.hScaleFactor
                fillMode: IconImage.Stretch
                source: "../resources/cardBackground.svg"
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

            VectorImage {
                id: tableCard4
                visible: false
                x: -2 * gamePage.hScaleFactor
                y: 0
                width: (52 + 4) * gamePage.hScaleFactor
                height: 72 * gamePage.hScaleFactor
                fillMode: IconImage.Stretch
                source: "../resources/cardBackground.svg"
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

            VectorImage {
                id: tableCard5
                visible: false
                x: -2 * gamePage.hScaleFactor
                y: 0
                width: (52 + 4) * gamePage.hScaleFactor
                height: 72 * gamePage.hScaleFactor
                fillMode: IconImage.Stretch
                source: "../resources/cardBackground.svg"
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
                Text {
                    text: GameTable ? qsTr("Pot: $") + GameTable.pot : qsTr("Pot: $0")
                    color: "#99D500"
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 13
                    font.bold: true
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

            // Obere Gegner-Reihe (Sitze 4, 5, 6 = P5, P6, P7) – oben angeheftet
            RowLayout {
                id: topPlayerRow
                anchors.top: parent.top
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.right: parent.right
                anchors.rightMargin: 4
                spacing: 4
                height: 76

                GamePlayerBox { Layout.fillWidth: true; height: parent.height; up: true; seatIndex: 4 }
                GamePlayerBox { Layout.fillWidth: true; height: parent.height; up: true; seatIndex: 5 }
                GamePlayerBox { Layout.fillWidth: true; height: parent.height; up: true; seatIndex: 6 }
            }

            // Linke Spieler-Spalte (Sitz 3 oben, Sitz 2 unten = P4, P3)
            Column {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                width: 112

                GamePlayerBox { width: parent.width; up: false; seatIndex: 3 }
                GamePlayerBox { width: parent.width; up: false; seatIndex: 2 }
            }

            // Rechte Spieler-Spalte (Sitz 7 oben, Sitz 8 unten = P8, P9)
            Column {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                width: 112

                GamePlayerBox { width: parent.width; up: false; seatIndex: 7 }
                GamePlayerBox { width: parent.width; up: false; seatIndex: 8 }
            }

            // Gemeinschaftskarten direkt unter der oberen Spielerreihe
            Column {
                anchors.top: topPlayerRow.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                // 5 Gemeinschaftskarten
                Row {
                    spacing: 3
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: (typeof GameTable !== "undefined" && GameTable) ? GameTable.boardCardCount : 0

                        Rectangle {
                            width: 52
                            height: 78
                            color: "transparent"
                            radius: 4

                            VectorImage {
                                anchors.fill: parent
                                source: {
                                    var cards = (typeof GameTable !== "undefined" && GameTable) ? GameTable.boardCards : null
                                    var cardIdx = (cards && index < cards.length) ? cards[index] : -1
                                    return Config.StaticData.cardSource(cardIdx)
                                }
                                fillMode: VectorImage.PreserveAspectFit
                            }
                        }
                    }
                }

                // Pott-Anzeige mit Dealer-Puck
                Row {
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter

                    VectorImage {
                        source: "../resources/tableDealerPuck.svg"
                        width: 26
                        height: 26
                        fillMode: VectorImage.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: GameTable ? qsTr("Pot: $") + GameTable.pot : qsTr("Pot: $0")
                        color: "#FFFF00"
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
            }

            // Untere Reihe: P2 (links, Sitz 1) + eigener Sitz (Mitte, Sitz 0) + P10 (rechts, Sitz 9)
            RowLayout {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.right: parent.right
                anchors.rightMargin: 4
                height: 88
                spacing: 4

                GamePlayerBox {
                    width: 112
                    height: parent.height
                    up: false
                    seatIndex: 1
                }

                GamePlayerSelfBox {
                    Layout.fillWidth: true
                    height: parent.height
                }

                GamePlayerBox {
                    width: 112
                    height: parent.height
                    up: false
                    seatIndex: 9
                }
            }
        }

        // 3. Action-Leiste: Fold / Call / Raise mit Tischstil-Buttons
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 54

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.82)
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 5; bottomMargin: 5 }
                spacing: 8

                VectorImage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    source: "../resources/tableActionFold.svg"
                    fillMode: VectorImage.PreserveAspectFit
                    opacity: GameTable && GameTable.myTurn ? 1.0 : 0.45
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (GameTable && GameTable.myTurn) GameTable.fold()
                    }
                }

                VectorImage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    source: "../resources/tableActionCall.svg"
                    fillMode: VectorImage.PreserveAspectFit
                    opacity: GameTable && GameTable.myTurn ? 1.0 : 0.45
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (GameTable && GameTable.myTurn) GameTable.call()
                    }
                }

                VectorImage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    source: "../resources/tableActionRaise.svg"
                    fillMode: VectorImage.PreserveAspectFit
                    opacity: GameTable && GameTable.myTurn ? 1.0 : 0.45
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (GameTable && GameTable.myTurn) GameTable.raise(0)
                    }
                }
            }
        }
    }
}
