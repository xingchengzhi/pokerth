pragma Singleton
import QtQuick 6.5
import QtCore

// import "../resources"

QtObject {
    id: root

    // 0 = Hell (Light), 1 = Dunkel (Dark), 2 = Automatisch
    // Synced from pokerth.qml Component.onCompleted and GuiSettings DarkMode ComboBox
    property int darkMode: 1

    readonly property bool isDark: darkMode !== 0  // 0=Hell → false, alles andere (1=Dunkel, 2=Auto) → true

    readonly property var languages: [
            { langName: "Deutsch (Deutsch)", code: "de_DE"},
            { langName: "English (English)", code: "en_US"},
            { langName: "French (Français)", code: "fr_FR"}
        ]

    function findSupportedLocale(systemName) {
        var closestMatch = "en_US" // Default
        var shortName = systemName.substring(0,2)
        for (var i = 0; i < languages.length; ++i) {
            var currentCode = languages[i].code;
            if (currentCode === systemName) {
                return systemName;
            }
            if (currentCode.substring(0,2) === shortName) {
                closestMatch = currentCode;
            }
        }

        return closestMatch;
    }

    // col100=primary text … col700=background — inverted between dark and light.
    // Using plain JS objects + property var so that changing `palette` triggers
    // re-evaluation of all `palette.secondary.colXXX` bindings reliably.
    readonly property var _dark: ({
        secondary: { col100:"#eff1f5", col200:"#cdd3e0", col300:"#a0acc4",
                     col400:"#7787a3", col500:"#576378", col600:"#394150", col700:"#1d222b" }
    })
    readonly property var _light: ({
        secondary: { col100:"#1d222b", col200:"#394150", col300:"#576378",
                     col400:"#7787a3", col500:"#a0acc4", col600:"#dce2ec", col700:"#f0f3f8" }
    })
    property var palette: isDark ? _dark : _light

    readonly property QtObject loadedFont: FontLoader {
        source: "../resources/Rubik-VariableFont_wght.ttf"
    }

    // Spektrum-Farben (angelehnt an pokerth.net Chart-Palette, Platz 1–10)
    readonly property var chartColors: [
        "#3dbd72",  // 1  – Smaragdgrün
        "#7bc64b",  // 2  – Limette
        "#b4c83f",  // 3  – Gelbgrün
        "#e2bf35",  // 4  – Gold
        "#e28230",  // 5  – Orange
        "#d44545",  // 6  – Rot
        "#cc3480",  // 7  – Pink
        "#a833c5",  // 8  – Violett
        "#6040cc",  // 9  – Indigo
        "#4060e0"   // 10 – Blau
    ]

    // Gibt eine kontrastgerechte Chart-Farbe zurück (hell in Dark-Mode, dunkel in Light-Mode)
    function chartColor(index, highlighted) {
        var c = Qt.color(chartColors[index % chartColors.length])
        if (highlighted) {
            return isDark ? c : Qt.darker(c, 1.45)
        } else {
            return isDark ? Qt.darker(c, 1.9) : Qt.darker(c, 2.8)
        }
    }

    readonly property var progressMessages: [
        "Shuffling the Decks ...",
        "Bribing the Dealer ...",
        "Manipulating the RNG ...",
        "Taking a break at the Bar ...",
        "Practicing Poker-Faces ...",
        "Going All-In ...",
        "Folding AAAA ...",
        "Raising Big Blind ...",
        "Stacking Chips ..."
    ]
}
