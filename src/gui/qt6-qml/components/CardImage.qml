import QtQuick 6.5
import QtQuick.VectorImage

import "../config" as Config

// Responsives Karten-Element.
// cardIndex: Engine-Kodierung 0-51 (-1 = Rückseite)
//   0-12 = Karo (♦), 13-25 = Herz (♥), 26-38 = Pik (♠), 39-51 = Kreuz (♣)
//   Rang: 0=2, 1=3, …, 8=10, 9=J, 10=Q, 11=K, 12=A
//
// Responsiv-Schwellenwert (angelehnt an die SVG-Media-Query des Originals ~75 px):
//   width < 56  → Mini-Darstellung: weißes Rechteck + Rang + Suit-Symbol
//   width ≥ 56  → Vollständige SVG-Karte (responsive-cards/{rank}{suit}.svg)
Item {
    id: root

    property int cardIndex: -1

    readonly property bool useMini: width < 56

    // ── Mapping-Tabellen ──────────────────────────────────────────────────────
    readonly property var _suits:       ["d", "h", "s", "c"]
    readonly property var _suitSymbols: ["♦", "♥", "♠", "♣"]
    readonly property var _suitColors:  ["#d40000", "#d40000", "#1a1a1a", "#1a1a1a"]
    readonly property var _ranks:       [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1]
    readonly property var _rankLabels:  ["2","3","4","5","6","7","8","9","10","J","Q","K","A"]

    readonly property bool   isFrontCard: Number.isInteger(cardIndex) && cardIndex >= 0 && cardIndex <= 51
    readonly property bool   isBack:      !isFrontCard
    readonly property int    si:          isFrontCard ? Math.floor(cardIndex / 13) : 0
    readonly property int    ri:          isFrontCard ? (cardIndex % 13) : 0
    readonly property string suitChar:    isFrontCard && si >= 0 && si < _suits.length ? String(_suits[si]) : ""
    readonly property string suitSymbol:  isFrontCard && si >= 0 && si < _suitSymbols.length ? String(_suitSymbols[si]) : ""
    readonly property color  suitColor:   isFrontCard && si >= 0 && si < _suitColors.length ? _suitColors[si] : "black"
    readonly property string rankLabel:   isFrontCard && ri >= 0 && ri < _rankLabels.length ? String(_rankLabels[ri]) : ""
    readonly property int    rankNum:     isFrontCard && ri >= 0 && ri < _ranks.length ? _ranks[ri] : -1

    // ── Kartenrückseite ────────────────────────────────────────────────────────
    VectorImage {
        visible: root.isBack
        anchors.fill: parent
        fillMode: VectorImage.Stretch
        source: root.isBack ? "qrc:resources/cardBackground.svg" : ""
    }

    // ── Vollständige SVG-Karte (≥ 56 px) ─────────────────────────────────────
    VectorImage {
        visible: !root.isBack && !root.useMini
        anchors.fill: parent
        fillMode: VectorImage.Stretch
        source: (!root.isBack && !root.useMini)
                ? "qrc:resources/responsive-cards/" + root.rankNum + root.suitChar + ".svg"
                : ""
    }

    // ── Mini-Karte (< 56 px) ──────────────────────────────────────────────────
    Rectangle {
        visible: !root.isBack && root.useMini
        anchors.fill: parent
        color: "white"
        border.color: "#888888"
        border.width: 0.5
        radius: Math.max(2, parent.width * 0.08)
        clip: true

        // Oben-links: Rang + Symbol
        Column {
            anchors {
                top:    parent.top
                left:   parent.left
                topMargin:  Math.max(1, Math.round(parent.height * 0.03))
                leftMargin: Math.max(1, Math.round(parent.width  * 0.07))
            }
            spacing: -1

            Text {
                text: root.rankLabel
                color: root.suitColor
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: Math.max(7, Math.round(root.width * 0.30))
                font.bold: true
                lineHeightMode: Text.FixedHeight
                lineHeight: font.pixelSize * 1.1
            }
            Text {
                text: root.suitSymbol
                color: root.suitColor
                font.pixelSize: Math.max(6, Math.round(root.width * 0.24))
                lineHeightMode: Text.FixedHeight
                lineHeight: font.pixelSize * 1.1
            }
        }

        // Unten-rechts: identisch, 180° gedreht
        Column {
            anchors {
                bottom: parent.bottom
                right:  parent.right
                bottomMargin: Math.max(1, Math.round(parent.height * 0.03))
                rightMargin:  Math.max(1, Math.round(parent.width  * 0.07))
            }
            spacing: -1
            rotation: 180

            Text {
                text: root.rankLabel
                color: root.suitColor
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: Math.max(7, Math.round(root.width * 0.30))
                font.bold: true
                lineHeightMode: Text.FixedHeight
                lineHeight: font.pixelSize * 1.1
            }
            Text {
                text: root.suitSymbol
                color: root.suitColor
                font.pixelSize: Math.max(6, Math.round(root.width * 0.24))
                lineHeightMode: Text.FixedHeight
                lineHeight: font.pixelSize * 1.1
            }
        }
    }
}
