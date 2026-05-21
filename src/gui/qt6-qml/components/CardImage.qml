import QtQuick 6.5

import "../config" as Config

// Responsives Karten-Element.
// cardIndex: Engine-Kodierung 0-51 (-1 = Rückseite)
//   0-12 = Karo (♦), 13-25 = Herz (♥), 26-38 = Pik (♠), 39-51 = Kreuz (♣)
//   Rang: 0=2, 1=3, …, 8=10, 9=J, 10=Q, 11=K, 12=A
//
// Die Karten werden über das schlanke 'cards-simple'-SVG-Set gerendert: großer
// zentrierter Rang + ein zentriertes Suit-Symbol. Diese Variante wurde aus den
// responsive-cards extrahiert (Rang- und Suit-Glyphen) und ist auch bei kleinen
// Größen optimal lesbar und beliebig hochskalierbar. Gerendert via 'Image'
// (Qt-SVG-Rasterizer), der die viewBox sauber auswertet.
Item {
    id: root

    property int cardIndex: -1

    // ── Mapping-Tabellen ──────────────────────────────────────────────────────
    readonly property var _suits: ["d", "h", "s", "c"]
    readonly property var _ranks: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1]

    readonly property bool   isFrontCard: Number.isInteger(cardIndex) && cardIndex >= 0 && cardIndex <= 51
    readonly property bool   isBack:      !isFrontCard
    readonly property int    si:          isFrontCard ? Math.floor(cardIndex / 13) : 0
    readonly property int    ri:          isFrontCard ? (cardIndex % 13) : 0
    readonly property string suitChar:    isFrontCard && si >= 0 && si < _suits.length ? String(_suits[si]) : ""
    readonly property int    rankNum:     isFrontCard && ri >= 0 && ri < _ranks.length ? _ranks[ri] : -1

    // ── Kartenrückseite ────────────────────────────────────────────────────────
    Image {
        visible: root.isBack
        anchors.fill: parent
        fillMode: Image.Stretch
        smooth: true
        sourceSize.width: 100
        sourceSize.height: 140
        source: root.isBack ? "qrc:resources/cardBackground.svg" : ""
    }

    // ── Vorderseite (responsive-cards SVG, via Image-Rasterizer) ────────────────
    Image {
        visible: !root.isBack
        anchors.fill: parent
        fillMode: Image.Stretch
        smooth: true
        sourceSize.width: 120
        sourceSize.height: 168
        source: !root.isBack
                ? "qrc:resources/cards-simple/" + root.rankNum + root.suitChar + ".svg"
                : ""
    }
}
