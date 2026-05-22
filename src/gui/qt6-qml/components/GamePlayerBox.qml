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

    // Letzte Aktion dieses Spielers (0=keine,1=Fold,2=Check,3=Call,4=Bet,5=Raise,6=All-In)
    readonly property int action: seatData && seatData.action !== undefined ? seatData.action : 0
    readonly property string actionText: {
        switch (root.action) {
        case 1: return qsTr("Fold")
        case 2: return qsTr("Check")
        case 3: return qsTr("Call")
        case 4: return qsTr("Bet")
        case 5: return qsTr("Raise")
        case 6: return qsTr("All-In")
        default: return ""
        }
    }

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

    // Aktions-Anzeige (Fold/Check/Call/Bet/Raise/All-In). Verschwindet automatisch
    // bei Rundenwechsel (Aktion=0).
    //  • oben/unten-Mitte (betSide bottom/top): links neben dem Einsatz
    //  • Seitenspieler: oberhalb des Einsatzes, an der zur Box zeigenden Innenkante
    //    ausgerichtet → bleibt stabil, auch wenn kein Einsatz gesetzt ist.
    Rectangle {
        id: actionBadge
        visible: root.actionText !== "" && !root.isWinner
        width: actionLabel.width + 14
        height: 18
        radius: 9
        color: Qt.rgba(0.04, 0.08, 0.18, 0.85)
        border.color: "#8fb4ff"
        border.width: 1
        z: 18

        readonly property bool sideBet: root.betSide === "left" || root.betSide === "right"
        // oben/unten-Mitte: linkes Element der zentrierten Gruppe [Action][Einsatz][Button]
        // Seiten: oberhalb des Einsatzes, an der Innenkante ausgerichtet (stabil)
        x: !sideBet ? betGroup.x
           : (root.betSide === "right" ? betGroup.x
                                       : betGroup.x + betGroup.width - width)
        // Seiten: oberer der drei festen Slots (Action/Einsatz/Icon) auf Boxhöhe.
        y: !sideBet ? (betGroup.y + (betGroup.height - height) / 2)
                    : (betGroup.y + betGroup.height / 6 - height / 2)

        Text {
            id: actionLabel
            anchors.centerIn: parent
            text: root.actionText
            color: "#eaf1ff"
            font.family: Config.StaticData.loadedFont.font.family
            font.pixelSize: 11
            font.bold: true
        }
    }

    // Einsatz (Chip + Betrag) + Dealer/Small-/Big-Blind-Button – gruppiert.
    // Oben/unten-Mitte (betSide top/bottom): Button rechts neben dem Einsatz,
    // beides zusammen zentriert. Seiten (betSide left/right): Button unter dem
    // Einsatz, beides vertikal zentriert.
    Item {
        id: betGroup
        visible: root.bet > 0 || root.button > 0
        z: 25

        readonly property bool horizontal: root.betSide === "bottom" || root.betSide === "top"
        readonly property int gap: 4
        readonly property bool actActive: root.actionText !== "" && !root.isWinner
        readonly property real actW: (horizontal && actActive) ? actionBadge.width : 0
        readonly property real actH: (horizontal && actActive) ? actionBadge.height : 0
        readonly property real betW: root.bet > 0 ? betRow.width : 0
        readonly property real betH: root.bet > 0 ? betRow.height : 0
        readonly property real btnW: root.button > 0 ? buttonImg.width : 0
        readonly property real btnH: root.button > 0 ? buttonImg.height : 0
        readonly property real bothGap: (root.bet > 0 && root.button > 0) ? gap : 0
        readonly property real actGap: (actW > 0 && (betW > 0 || btnW > 0)) ? gap : 0

        // Horizontal (Player 5): [Action][Einsatz][Button] – zentriert unter der Box.
        // Seiten: die Gruppe überspannt die volle Boxhöhe; Einsatz und Button sitzen
        // in festen Slots (Mitte/unten), damit nichts verrutscht.
        width: horizontal ? (actW + actGap + betW + bothGap + btnW) : Math.max(betW, btnW)
        height: horizontal ? Math.max(actH, betH, btnH) : playerBox.height

        x: root.betSide === "right" ? playerBox.width + 3
         : root.betSide === "left"  ? -width - 3
         : (playerBox.width - width) / 2
        y: root.betSide === "bottom" ? playerBox.height + 2
         : root.betSide === "top"    ? -height - 2
         : (playerBox.height - height) / 2

        Row {
            id: betRow
            visible: root.bet > 0
            spacing: 2
            x: betGroup.horizontal ? (betGroup.actW + betGroup.actGap) : (betGroup.width - width) / 2
            // Seiten: mittlerer fester Slot; horizontal: in der Zeile zentriert.
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
                font.pixelSize: 11
                font.bold: true
                text: "$" + root.bet
            }
        }

        Image {
            id: buttonImg
            visible: root.button > 0
            width: 22
            height: 22
            fillMode: Image.PreserveAspectFit
            x: betGroup.horizontal
               ? (betGroup.actW + betGroup.actGap + betGroup.betW + betGroup.bothGap)
               : (betGroup.width - width) / 2
            // Seiten: unterer fester Slot; horizontal: in der Zeile zentriert.
            y: betGroup.horizontal
               ? (betGroup.height - height) / 2
               : (betGroup.height * 5 / 6 - height / 2)
            source: root.button === 1 ? "../resources/tableDealerPuck.svg"
                  : root.button === 2 ? "../resources/tableSmallBlind.svg"
                  : root.button === 3 ? "../resources/tableBigBlind.svg"
                  : ""
        }
    }
}
