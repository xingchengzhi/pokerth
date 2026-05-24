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

    // Letzte Aktion (0=keine,1=Fold,2=Check,3=Call,4=Bet,5=Raise,6=All-In)
    readonly property int action: selfData && selfData.action !== undefined ? selfData.action : 0
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

    // Ich habe gefoldet → eigene Karten durchscheinend (wie im Qt-Widgets-Client)
    readonly property bool folded: selfData && selfData.folded !== undefined ? selfData.folded : false
    // Spieler im Spiel? Wer kein Geld mehr für die nächste Hand hat, ist inaktiv.
    readonly property bool playerActive: selfData && selfData.active !== undefined ? selfData.active : true
    // Gesetzter Avatar (file://-URL) bzw. "" → Platzhalter
    readonly property string avatarSource: selfData && selfData.avatar !== undefined ? selfData.avatar : ""

    color: "transparent"

    // Informationsdichte: gefoldet → dezent zurücknehmen, raus aus dem Spiel →
    // deutlich abdunkeln (analog zu den Gegnerboxen).
    opacity: !root.playerActive ? 0.4 : (root.folded ? 0.78 : 1.0)
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

    // Am Zug leicht „angehoben" (Tiefe/Fokus, sanfter Übergang).
    scale: root.isMyTurn ? 1.03 : 1.0
    transformOrigin: Item.Center
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

    // Hintergrund mit dezentem Verlauf + weichem Schlagschatten → angehobene Karte.
    Rectangle {
        anchors.fill: parent
        radius: 6
        opacity: 0.9
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Config.StaticData.palette.secondary.col600, 1.18) }
            GradientStop { position: 1.0; color: Config.StaticData.palette.secondary.col700 }
        }
        border.color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.42
            shadowBlur: 0.9
            shadowVerticalOffset: 3
            shadowHorizontalOffset: 0
        }
    }

    // Highlight: weicher Außen-Glow wenn ich am Zug bin – mit ruhigem Puls.
    Rectangle {
        id: turnGlow
        anchors.fill: parent
        anchors.margins: -2
        color: "transparent"
        radius: 6
        border.color: root.isMyTurn ? "#CCFFD54A" : "transparent"
        border.width: root.isMyTurn ? 2 : 0
        z: 10

        layer.enabled: root.isMyTurn
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#FFD700"
            shadowOpacity: 0.9
            shadowBlur: 1.0
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }

        SequentialAnimation on opacity {
            running: root.isMyTurn
            loops: Animation.Infinite
            NumberAnimation { from: 0.65; to: 1.0; duration: 750; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.0; to: 0.65; duration: 750; easing.type: Easing.InOutSine }
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
                fillMode: root.avatarSource !== "" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                source: root.avatarSource !== "" ? root.avatarSource : "qrc:resources/pokerth.svg"
                asynchronous: true
                cache: true
                // Raus aus dem Spiel → Avatar entsättigen.
                layer.enabled: !root.playerActive
                layer.effect: MultiEffect { saturation: -1.0 }
            }
        }

        Rectangle {
            x: cardsArea.sx + cardsArea.avatarSize + cardsArea.gap
            y: (parent.height - height) / 2
            width: cardsArea.cardW
            height: cardsArea.cardH
            color: "transparent"
            // Raus aus dem Spiel (kein Geld mehr) → Karten ganz ausblenden;
            // bei Fold (noch im Spiel) nur durchscheinend.
            visible: root.playerActive
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
            // Raus aus dem Spiel (kein Geld mehr) → Karten ganz ausblenden;
            // bei Fold (noch im Spiel) nur durchscheinend.
            visible: root.playerActive
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
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
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

    // Aktion + Einsatz (Chip + Betrag) + Dealer/Small-/Big-Blind-Button oberhalb
    // der Box. FESTE Slots (wie bei Player 5): die Gruppe überspannt die volle
    // Boxbreite → Action links, Einsatz mittig, Button rechts. So verrutscht
    // nichts, egal welche Elemente gerade aktiv sind.
    Item {
        id: betGroup
        readonly property bool actActive: root.actionText !== "" && !root.isWinner
        visible: root.bet > 0 || root.button > 0 || actActive
        z: 25

        readonly property real actH: actActive ? actionBadge.height : 0
        readonly property real betH: root.bet > 0 ? betRow.height : 0
        readonly property real btnH: root.button > 0 ? buttonImg.height : 0

        width: root.width
        height: Math.max(actH, betH, btnH)
        x: 0
        y: -height - 2

        // Action-Badge – fester Slot links
        Rectangle {
            id: actionBadge
            visible: betGroup.actActive
            width: actionLabel.width + 16
            height: 20
            radius: 10
            // Farbe je Aktion (gleiche Logik wie die Action-Buttons, nur dunkler).
            color: Config.Theme.actionBadgeColor(root.action)
            border.color: Config.Theme.actionBadgeBorder(root.action)
            border.width: 1
            x: 0
            y: (betGroup.height - height) / 2
            transformOrigin: Item.Center
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            // Pop beim Erscheinen einer neuen Aktion (Mikroanimation).
            onVisibleChanged: if (visible) selfBadgePop.restart()
            SequentialAnimation {
                id: selfBadgePop
                NumberAnimation { target: actionBadge; property: "scale"; from: 0.6; to: 1.12; duration: 110; easing.type: Easing.OutQuad }
                NumberAnimation { target: actionBadge; property: "scale"; to: 1.0; duration: 120; easing.type: Easing.OutBack }
            }

            Text {
                id: actionLabel
                anchors.centerIn: parent
                text: root.actionText
                color: "#eaf1ff"
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 12
                font.bold: true
            }
        }

        // Einsatz – fester Slot mittig
        Row {
            id: betRow
            visible: root.bet > 0
            spacing: 2
            x: (betGroup.width - width) / 2
            y: (betGroup.height - height) / 2
            transformOrigin: Item.Center
            // Chip „poppt" beim Setzen rein (Mikroanimation).
            onVisibleChanged: if (visible) betPopSelf.restart()
            SequentialAnimation {
                id: betPopSelf
                NumberAnimation { target: betRow; property: "scale"; from: 0.5; to: 1.15; duration: 110; easing.type: Easing.OutQuad }
                NumberAnimation { target: betRow; property: "scale"; to: 1.0; duration: 130; easing.type: Easing.OutBack }
            }

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

        // Dealer/Blind-Button – fester Slot rechts
        Image {
            id: buttonImg
            visible: root.button > 0
            width: 26
            height: 26
            fillMode: Image.PreserveAspectFit
            x: betGroup.width - width
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
        anchors.bottomMargin: 3
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
