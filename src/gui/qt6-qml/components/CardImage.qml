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

    readonly property bool isBack: !(Number.isInteger(cardIndex) && cardIndex >= 0 && cardIndex <= 51)

    // Vorderseiten-Quelle in EINER Bindung berechnen (nur von cardIndex abhängig),
    // damit beim Wechsel keine ungültigen Zwischenpfade wie "-1s.svg" entstehen.
    readonly property string frontSource: {
        if (isBack)
            return ""
        var suits = ["d", "h", "s", "c"]
        var ranks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1]
        return "qrc:resources/cards-simple/" + ranks[cardIndex % 13] + suits[Math.floor(cardIndex / 13)] + ".svg"
    }

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

    // ── Vorderseite (cards-simple SVG, via Image-Rasterizer) ────────────────────
    Image {
        visible: !root.isBack
        anchors.fill: parent
        fillMode: Image.Stretch
        smooth: true
        sourceSize.width: 120
        sourceSize.height: 168
        source: root.frontSource
    }
}
