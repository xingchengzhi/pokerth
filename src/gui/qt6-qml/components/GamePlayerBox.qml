import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import "../config" as Config

Item {
    id: root

    property bool up: false
    property int seatIndex: 0
    // Winner-Badge unterhalb statt oberhalb der Box anzeigen – nur für die oberste
    // Box (Player 5) im Hochformat sinnvoll, sonst würde es oben anstoßen.
    property bool winnerBelow: false
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
    // Spieler hat gefoldet → Karten durchscheinend (wie im Qt-Widgets-Client)
    readonly property bool folded: seatData && seatData.folded !== undefined ? seatData.folded : false
    // Gesetzter Avatar (file://-URL) bzw. "" → Platzhalter
    readonly property string avatarSource: seatData && seatData.avatar !== undefined ? seatData.avatar : ""

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

    // Informationsdichte: wer raus ist (kein Geld mehr → !isActive) wird deutlich
    // abgedunkelt, wer nur gefoldet hat dezent zurückgenommen. So heben sich der
    // aktive Spieler und die noch laufende Hand klarer hervor.
    opacity: !root.isActive ? Config.Theme.dimmedOpacity
           : (root.folded ? 0.72 : 1.0)
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

    // ── Hauptbox ────────────────────────────────────────────────────────────────
    Rectangle {
        id: playerBox
        anchors.fill: parent
        color: "transparent"

        // Aktiver Spieler leicht „angehoben" → mehr Tiefe/Fokus (sanfter Übergang).
        scale: root.isMyTurn ? 1.04 : 1.0
        transformOrigin: Item.Center
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

        // Karten-Hintergrund mit dezentem Verlauf + weichem Schlagschatten → die
        // Box wirkt als angehobene Karte statt als flache Fläche.
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

        // Highlight: weicher Außen-Glow wenn dieser Spieler am Zug ist – mit
        // ruhigem Puls, damit der Blick zum aktiven Spieler geführt wird.
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

        // Avatar + Karten – horizontale Abstände einheitlich (linker Außenrand =
        // Abstand Avatar↔Karten = rechter Außenrand = hMargin)
        readonly property int hMargin: 4

        Row {
            id: topRow
            width: parent.width - 2 * playerBox.hMargin
            height: parent.height - 26
            x: playerBox.hMargin
            y: 4
            spacing: playerBox.hMargin

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
                    fillMode: root.avatarSource !== "" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                    source: root.avatarSource !== "" ? root.avatarSource : "qrc:resources/pokerth.svg"
                    asynchronous: true
                    cache: true
                    // Raus aus dem Spiel → Avatar entsättigen (klares "out"-Signal).
                    layer.enabled: !root.isActive
                    layer.effect: MultiEffect { saturation: -1.0 }
                }
            }

            Item {
                id: cardsLane
                width: topRow.width - avatarBox.width - topRow.spacing
                height: parent.height

                // Raus aus dem Spiel (kein Geld mehr → inaktiv) → Karten ganz
                // ausblenden; bei Fold (noch im Spiel) nur durchscheinend.
                visible: root.isActive
                opacity: root.folded ? 0.3 : 1.0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

                readonly property int cardSpacing: 3
                readonly property int cardH: height
                // Original-Seitenverhältnis der Karten (SVG-viewBox 120×168, wie der
                // Community-Cards-Bereich) → Höhe beibehalten, Breite ergibt sich daraus.
                readonly property int cardW: Math.round(cardH * 120 / 168)
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

        // Name + Stack – unterer Außenrand = oberer Außenrand (topRow.y)
        Row {
            width: parent.width - 2 * playerBox.hMargin
            height: 13
            x: playerBox.hMargin
            y: parent.height - height - topRow.y

            Text {
                width: parent.width / 2
                horizontalAlignment: Text.AlignLeft
                color: Config.StaticData.palette.secondary.col100
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 0.3
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

    // WINNER-Badge: standardmäßig über der Box; nur die oberste Box (Player 5)
    // zeigt es unterhalb (oben würde es am Bildschirmrand anstoßen). Etwas mehr
    // vertikaler Abstand zur Box.
    Rectangle {
        visible: root.isWinner
        anchors.horizontalCenter: playerBox.horizontalCenter
        anchors.top: root.winnerBelow ? playerBox.bottom : undefined
        anchors.bottom: root.winnerBelow ? undefined : playerBox.top
        anchors.topMargin: root.winnerBelow ? 3 : 0
        anchors.bottomMargin: root.winnerBelow ? 0 : 3
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

    // Aktions-Anzeige (Fold/Check/Call/Bet/Raise/All-In) – zentriert über den
    // Hole-Cards in den normalen Player-Boxen.
    Rectangle {
        id: actionBadge
        visible: root.actionText !== "" && !root.isWinner
        width: actionLabel.width + 14
        height: 18
        radius: 9
        // Farbe je Aktion (gleiche Logik wie die Action-Buttons, nur dunkler).
        color: Config.Theme.actionBadgeColor(root.action)
        border.color: Config.Theme.actionBadgeBorder(root.action)
        border.width: 1
        z: 18
        transformOrigin: Item.Center
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        // Pop beim Erscheinen einer neuen Aktion (Mikroanimation).
        onVisibleChanged: if (visible) badgePop.restart()
        SequentialAnimation {
            id: badgePop
            NumberAnimation { target: actionBadge; property: "scale"; from: 0.6; to: 1.12; duration: 110; easing.type: Easing.OutQuad }
            NumberAnimation { target: actionBadge; property: "scale"; to: 1.0; duration: 120; easing.type: Easing.OutBack }
        }

        readonly property real cardsCenterX: playerBox.x
                            + topRow.x
                            + cardsLane.x
                            + cardsLane.sx
                            + cardsLane.totalW / 2
        readonly property real cardsCenterY: playerBox.y
                            + topRow.y
                            + topRow.height / 2
        x: cardsCenterX - width / 2
        y: cardsCenterY - height / 2

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
        readonly property real betW: root.bet > 0 ? betRow.width : 0
        readonly property real betH: root.bet > 0 ? betRow.height : 0
        readonly property real btnW: root.button > 0 ? buttonImg.width : 0
        readonly property real btnH: root.button > 0 ? buttonImg.height : 0

        // Oben/unten (z. B. Player 5): die Gruppe überspannt die volle Boxbreite,
        // damit Einsatz und Button in FESTEN Slots sitzen (Einsatz mittig, Button
        // rechts) und nicht verrutschen – unabhängig davon, ob ein Action-Badge
        // aktiv ist. Seiten (left/right): volle Boxhöhe, Einsatz Mitte, Button unten.
        width: horizontal ? playerBox.width : Math.max(betW, btnW)
        height: horizontal ? Math.max(betH, btnH) : playerBox.height

        x: root.betSide === "right" ? playerBox.width + 3
         : root.betSide === "left"  ? -width - 3
         : 0
        y: root.betSide === "bottom" ? playerBox.height + 2
         : root.betSide === "top"    ? -height - 2
         : (playerBox.height - height) / 2

        // Einsatz – immer mittig (horizontal: Box-Mitte; Seiten: mittlerer Slot).
        Row {
            id: betRow
            visible: root.bet > 0
            spacing: 2
            x: (betGroup.width - width) / 2
            y: (betGroup.height - height) / 2
            transformOrigin: Item.Center
            // Chip „poppt" beim Setzen rein (Mikroanimation).
            onVisibleChanged: if (visible) betPop.restart()
            SequentialAnimation {
                id: betPop
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
                font.pixelSize: 11
                font.bold: true
                text: "$" + root.bet
            }
        }

        // Dealer/Blind-Button – horizontal: fest am rechten Boxrand; Seiten: unterer Slot.
        Image {
            id: buttonImg
            visible: root.button > 0
            width: 22
            height: 22
            fillMode: Image.PreserveAspectFit
            x: betGroup.horizontal
               ? (betGroup.width - width)
               : (root.betSide === "right" ? 0 : (betGroup.width - width))
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
