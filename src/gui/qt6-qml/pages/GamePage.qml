import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.VectorImage
import QtQuick.Window

import "../components"
import "../config" as Config

Rectangle {
    id: gamePage
    objectName: "gamePage"
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    color: "transparent"

    function applyPlayingMode(index) {
        if (!actionBar)
            return
        actionBar.playingMode = index
        // Falls bereits mein Zug: gewählten Auto-Modus ausführen – aber
        // VERZÖGERT (Qt.callLater), niemals synchron. Diese Funktion läuft u.a.
        // aus dem activated-Handler der Modus-ComboBox bzw. aus einem Shortcut.
        // fold()/call() verändert sofort den Spielzustand und löst ein erneutes
        // myTurnChanged + Re-Layout der ActionBar (inkl. dieser ComboBox) aus;
        // synchron mitten im Klick-/Signal-Handler führte das zu Re-Entrancy
        // (lokales Spiel fror ein, Netzwerk-Spiel stürzte ab).
        if (GameTable && GameTable.myTurn)
            Qt.callLater(gamePage.runAutoAction)
    }

    // Auto-Modus-Aktion im nächsten Event-Loop-Durchlauf ausführen. Der Zustand
    // wird erneut geprüft, da er sich seit der Planung geändert haben kann
    // (z.B. Zug bereits vorbei). Qt.callLater dedupliziert Mehrfachaufrufe.
    function runAutoAction() {
        if (!actionBar || !GameTable || !GameTable.myTurn)
            return
        if (actionBar.playingMode === 2) {            // Auto Check/Fold
            if (actionBar.canCheck) GameTable.call()
            else GameTable.fold()
        } else if (actionBar.playingMode === 1) {     // Auto Check/Call
            GameTable.call()
        }
    }

    function toggleLogOverlay() {
        if (!tableZone)
            return
        tableZone.showLog = !tableZone.showLog
        if (tableZone.showLog && !tableZone.wide)
            tableZone.showChat = false
    }

    function toggleChatOverlay() {
        if (!tableZone)
            return
        tableZone.showChat = !tableZone.showChat
        if (tableZone.showChat && !tableZone.wide)
            tableZone.showLog = false
    }

    function toggleFullscreenMode() {
        var win = gamePage.Window.window
        if (!win)
            return
        if (win.visibility === Window.FullScreen)
            win.visibility = Window.Windowed
        else
            win.visibility = Window.FullScreen
    }

    Shortcut {
        sequence: "Alt+L"
        context: Qt.ApplicationShortcut
        enabled: gamePage.visible
        onActivated: gamePage.toggleLogOverlay()
    }
    Shortcut {
        sequence: "Alt+C"
        context: Qt.ApplicationShortcut
        enabled: gamePage.visible
        onActivated: gamePage.toggleChatOverlay()
    }
    Shortcut {
        sequence: "Alt+F"
        context: Qt.ApplicationShortcut
        enabled: gamePage.visible
        onActivated: gamePage.applyPlayingMode(2)
    }
    Shortcut {
        sequence: "Alt+M"
        context: Qt.ApplicationShortcut
        enabled: gamePage.visible
        onActivated: gamePage.applyPlayingMode(0)
    }
    Shortcut {
        sequence: "Alt+K"
        context: Qt.ApplicationShortcut
        enabled: gamePage.visible
        onActivated: gamePage.applyPlayingMode(1)
    }
    Shortcut {
        sequence: "F11"
        context: Qt.ApplicationShortcut
        enabled: gamePage.visible
        onActivated: gamePage.toggleFullscreenMode()
    }

    Image {
        id: gameBackground
        source: "../resources/gameBackground.svg"
        fillMode: Image.PreserveAspectCrop
        width: parent.width
        height: parent.height
    }


    // ── Tisch-Layout (Hoch- & Querformat) ─────────────────────────────────────
    // Einheitlicher Aufbau für alle Fenstergrößen:
    //   Status-Leiste → großer Tisch (alle Spieler überlagert) → Action-Leiste.
    // Die Spieler-Slots ordnen sich je nach Tisch-Seitenverhältnis (hoch/breit)
    // automatisch um – kein separates Desktop-Layout mehr.
    ColumnLayout {
        id: portraitLayout
        anchors.fill: parent
        spacing: 0

        // 1. Status-Leiste: Spielphase | Pott | Hand-Nummer
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Qt.rgba(0, 0, 0, 0.78)

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 0

                Text {
                    text: GameTable ? GameTable.phaseText : qsTr("Preflop")
                    color: "#FFFFFF"
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                }
                Item { Layout.fillWidth: true }
                Column {
                    spacing: 0
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Pot: $%1").arg(GameTable ? GameTable.pot : 0)
                        color: "#99D500"
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 15
                        font.bold: true
                        font.letterSpacing: 0.3
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Total: $%1").arg(GameTable ? GameTable.totalPot : 0)
                        color: "#7aa800"
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.letterSpacing: 0.3
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: qsTr("Hand %1").arg(GameTable ? GameTable.handNumber : 1)
                    color: "#bdbdbd"
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.letterSpacing: 0.5
                }
            }
        }

        // 2. Tischzone: grüne Tischgrafik füllt gesamten Platz, alle Spieler überlagert
        Item {
            id: tableZone
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Grüne Tischgrafik füllt die gesamte Zone. Unten am Bild liegt der
            // hölzerne Tischrand → Crop am unteren Rand ausrichten, damit dieser
            // auch im breiten Querformat sichtbar bleibt (im Hochformat ohnehin).
            // Querformat: reicht hinter der geschrumpften Action-Box bis zum
            // unteren Bildschirmrand, damit dort kein dunkler Streifen bleibt.
            Image {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height + (tableZone.wide ? actionBar.height : 0)
                source: "../resources/tableGreen.png"
                fillMode: Image.PreserveAspectCrop
                verticalAlignment: Image.AlignBottom
                smooth: true
            }

            // Anzahl der besetzten Sitze
            readonly property int seatCount: {
                if (typeof GameTable === "undefined" || !GameTable) return 1
                var c = 0
                for (var i = 0; i < GameTable.players.length; i++)
                    if (GameTable.players[i].name !== "") c++
                return Math.max(c, 1)
            }

            // Breiter Tisch (Querformat) vs. hoher Tisch (Hochformat) – die
            // Spieler-Slots ordnen sich je nach Seitenverhältnis automatisch um.
            readonly property bool wide: width >= height

            // Gegner-Boxen wachsen mit der Fensterbreite (eindeutige Referenz):
            // Faktor 1.0 bei Telefonbreite (~390px), linear hoch bis zum Maximum
            // (= Höhe der Self-Box) bei Vollbildbreite (~1920px).
            readonly property int oppBaseHeight: wide ? 80 : 64
            // Breite einer Gegner-Box (= seatSlot.width), Basis für die Abstandsprüfung.
            readonly property int oppBaseWidth: wide ? 125 : 107
            readonly property real oppScale: {
                var cap = selfBox.height / oppBaseHeight
                var t = (width - 390) / (1920 - 390)
                var s = Math.max(1.0, Math.min(cap, 1.0 + t * (cap - 1.0)))
                // Querformat: die oberen Boxen sitzen eng im Bogen. Skalierung so
                // begrenzen, dass benachbarte Boxen mind. 20px horizontalen Abstand
                // behalten – sonst überlappen sie am Umschalt-Breakpoint.
                if (wide && width > 0) {
                    var sq = slotSeq[seatCount - 1] || []
                    var xs = []
                    for (var i = 0; i < sq.length; ++i) {
                        var p = slotPos[sq[i]]
                        if (p && p[1] < 0.30) xs.push(p[0])   // nur die obere Reihe
                    }
                    xs.sort(function(a, b) { return a - b })
                    for (var j = 1; j < xs.length; ++j) {
                        var maxArc = ((xs[j] - xs[j - 1]) * width - 20) / oppBaseWidth
                        if (maxArc < s) s = maxArc
                    }
                }
                return s
            }

            // Feste Slot-Positionen (Mittelpunkt der Box als Anteil 0..1 der Zone).
            // Hochformat: 3 oben, Rest an den Seiten nach unten.
            readonly property var slotPosPortrait: ({
                "L_bottom": [0.18, 0.72],
                "L_lower":  [0.18, 0.59],
                "L_upper":  [0.18, 0.32],
                "TL":       [0.18, 0.19],
                "TC":       [0.50, 0.055],
                "TR":       [0.82, 0.19],
                "R_upper":  [0.82, 0.32],
                "R_lower":  [0.82, 0.59],
                "R_bottom": [0.82, 0.72]
            })
            // Querformat: breiter Oval-Tisch – Gegner bogenförmig oben + an den
            // Seiten verteilt, eigene Box unten in der Mitte.
            readonly property var slotPosLandscape: ({
                "BL":  [0.16, 0.70],
                "L":   [0.10, 0.44],
                "TLo": [0.19, 0.19],
                "TL":  [0.35, 0.15],
                "TC":  [0.50, 0.13],
                "TR":  [0.65, 0.15],
                "TRo": [0.81, 0.19],
                "R":   [0.90, 0.44],
                "BR":  [0.84, 0.70]
            })
            readonly property var slotPos: wide ? slotPosLandscape : slotPosPortrait

            // Slot-Reihenfolge je nach Gegnerzahl M – symmetrisch links/rechts verteilt,
            // damit unabhängig von der Spielerzahl Kreis-Symmetrie entsteht.
            readonly property var slotSeqPortrait: ({
                1: ["TC"],
                2: ["TL", "TR"],
                3: ["TL", "TC", "TR"],
                4: ["L_upper", "TL", "TR", "R_upper"],
                5: ["L_upper", "TL", "TC", "TR", "R_upper"],
                6: ["L_lower", "L_upper", "TL", "TR", "R_upper", "R_lower"],
                7: ["L_lower", "L_upper", "TL", "TC", "TR", "R_upper", "R_lower"],
                8: ["L_bottom", "L_lower", "L_upper", "TL", "TR", "R_upper", "R_lower", "R_bottom"],
                9: ["L_bottom", "L_lower", "L_upper", "TL", "TC", "TR", "R_upper", "R_lower", "R_bottom"]
            })
            readonly property var slotSeqLandscape: ({
                1: ["TC"],
                2: ["TL", "TR"],
                3: ["TL", "TC", "TR"],
                4: ["TLo", "TL", "TR", "TRo"],
                5: ["TLo", "TL", "TC", "TR", "TRo"],
                6: ["L", "TLo", "TL", "TR", "TRo", "R"],
                7: ["L", "TLo", "TL", "TC", "TR", "TRo", "R"],
                8: ["BL", "L", "TLo", "TL", "TR", "TRo", "R", "BR"],
                9: ["BL", "L", "TLo", "TL", "TC", "TR", "TRo", "R", "BR"]
            })
            readonly property var slotSeq: wide ? slotSeqLandscape : slotSeqPortrait

            // ── Gemeinschaftskarten + Pot – im oberen Tischbereich ───────────────
            Item {
                id: communityArea
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                // Portrait: mittig zwischen oberen (0.32·H) und unteren Seiten-Boxen
                // (0.59·H); die per seatNudge gespreizten unteren Boxen verschieben
                // den Mittelpunkt um (14−4)/2 = 5px nach unten.
                // Widescreen: mittig zwischen oberster Spielerreihe (TC ≈ 0.13·H)
                // und der Self-Box.
                anchors.verticalCenterOffset: tableZone.wide
                    ? (tableZone.height * 0.13 + (selfBox.y + selfBox.height / 2)) / 2 - tableZone.height / 2
                    : -tableZone.height * 0.045 + 5
                // Größe = nur die Kartenreihe; das Winning-Hand-Badge liegt als
                // Overlay darunter und zählt NICHT zur Größe → die Karten bleiben
                // zentriert und rutschen nicht nach oben, wenn das Badge erscheint.
                width: cardRow.width
                height: cardRow.height
                z: 0
                // Wächst mit der Fensterbreite wie die Gegner-Boxen; Kartenhöhe
                // maximal = Höhe der Self-Box (Basis 64 × oppScale → max 82).
                // Skalierung um die Mitte, damit die Position erhalten bleibt.
                transformOrigin: Item.Center
                scale: tableZone.oppScale

                // Inline-Komponente für einen einzelnen Board-Card-Slot
                // Karten-Seitenverhältnis 120:168 (≈0,714) – Karte = Platzhalter (1:1)
                component CommunitySlot: Item {
                    property int boardIndex: 0
                    width: 46; height: 64

                    readonly property bool isDealt: {
                        var cnt = (typeof GameTable !== "undefined" && GameTable)
                                  ? GameTable.boardCardCount : 0
                        return boardIndex < cnt
                    }

                    // Platzhalter-Rahmen (immer sichtbar)
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: Qt.rgba(0, 0, 0, 0.30)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.38)
                    }

                    // Aufgedeckte Karte – mit Einblend-Animation
                    CardImage {
                        id: faceCard
                        anchors.fill: parent
                        opacity: 0
                        cardIndex: {
                            var cards = (typeof GameTable !== "undefined" && GameTable)
                                        ? GameTable.boardCards : null
                            return (cards && boardIndex < cards.length) ? cards[boardIndex] : -1
                        }
                    }

                    onIsDealtChanged: {
                        if (isDealt) {
                            cardReveal.start()
                        } else {
                            faceCard.opacity = 0
                        }
                    }

                    SequentialAnimation {
                        id: cardReveal
                        // Flop-Karten staffeln (0 ms, 120 ms, 240 ms); Turn/River sofort
                        PauseAnimation { duration: boardIndex < 3 ? boardIndex * 120 : 0 }
                        NumberAnimation {
                            target: faceCard
                            property: "opacity"
                            from: 0; to: 1
                            duration: 260
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                // Weicher Lichtschein hinter den Gemeinschaftskarten → Fokus auf die
                // Tischmitte (dezent, warm).
                Rectangle {
                    anchors.centerIn: cardRow
                    width: cardRow.width + 80
                    height: cardRow.height + 54
                    radius: height / 2
                    color: Qt.rgba(1.0, 0.93, 0.72, 0.12)
                    z: -1
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 48
                        autoPaddingEnabled: true
                    }
                }

                // 5 Slots: Flop (0-2) | Turn (3) | River (4)
                Row {
                    id: cardRow
                    anchors.centerIn: parent
                    spacing: 3

                    CommunitySlot { boardIndex: 0 }
                    CommunitySlot { boardIndex: 1 }
                    CommunitySlot { boardIndex: 2 }

                    Item { width: 8; height: 1 }

                    CommunitySlot { boardIndex: 3 }

                    Item { width: 8; height: 1 }

                    CommunitySlot { boardIndex: 4 }
                }

                // Pot prominent in der Tischmitte (über den Karten): Chip-Icon +
                // Betrag mit goldenem Glow. Poppt bei Pot-Erhöhung (Mikroanimation).
                Rectangle {
                    id: potBadge
                    anchors.horizontalCenter: cardRow.horizontalCenter
                    anchors.bottom: cardRow.top
                    // Gleicher Abstand zur Kartenreihe wie das Winning-Hand-Badge
                    // darunter; Portrait kompakter (6) als Querformat (8). Skaliert
                    // mit oppScale, da innerhalb communityArea.
                    anchors.bottomMargin: tableZone.wide ? 8 : 6
                    visible: (typeof GameTable !== "undefined" && GameTable) ? GameTable.totalPot > 0 : false
                    width: potRow.width + 16
                    height: 24
                    radius: 12
                    color: Qt.rgba(0, 0, 0, 0.62)
                    border.color: Config.Theme.colorAccent
                    border.width: 1
                    transformOrigin: Item.Center

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Config.Theme.colorAccent
                        shadowOpacity: 0.45
                        shadowBlur: 0.9
                        shadowVerticalOffset: 0
                    }

                    Row {
                        id: potRow
                        anchors.centerIn: parent
                        spacing: 4
                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 13; height: 13
                            source: "../resources/chipStack.svg"
                            fillMode: Image.PreserveAspectFit
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "$" + (GameTable ? GameTable.totalPot : 0)
                            color: Config.Theme.colorAccent
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 0.3
                        }
                    }

                    SequentialAnimation {
                        id: potPop
                        NumberAnimation { target: potBadge; property: "scale"; from: 1.0; to: 1.18; duration: 110; easing.type: Easing.OutQuad }
                        NumberAnimation { target: potBadge; property: "scale"; to: 1.0; duration: 170; easing.type: Easing.OutBack }
                    }
                    Connections {
                        target: (typeof GameTable !== "undefined") ? GameTable : null
                        function onTotalPotChanged() {
                            if (GameTable && GameTable.totalPot > 0) potPop.restart()
                        }
                    }
                }

            }

            // Gewinner-Hand (z.B. "Full House") – nur während des Showdowns.
            // Als eigenes Top-Level-Element (NICHT in communityArea), damit es
            // unabhängig von deren z/Scale immer ÜBER den Spielerboxen liegt –
            // in Hoch- UND Querformat. Positioniert knapp unter den (skalierten)
            // Community Cards.
            Rectangle {
                id: winHandBadge
                z: 50   // über Boxen (z:1), unter den Overlays (z:150)
                visible: (typeof GameTable !== "undefined" && GameTable)
                         ? GameTable.winningHandText !== "" : false
                anchors.horizontalCenter: parent.horizontalCenter
                // Abstand zur Kartenreihe identisch zum Pot-Badge oben
                // (Portrait 6, Querformat 8 – jeweils · oppScale). Setzt direkt am
                // (skalierten) Mittelpunkt der communityArea an, folgt damit deren
                // Zentrierung in Hoch- UND Querformat.
                y: communityArea.y + communityArea.height / 2
                   + (communityArea.height * communityArea.scale) / 2
                   + (tableZone.wide ? 8 : 6) * communityArea.scale
                width: winHandLabel.implicitWidth + 22
                height: 26
                radius: 13
                color: Qt.rgba(0.05, 0.24, 0.05, 0.92)
                border.color: "#FFD700"
                border.width: 1
                transformOrigin: Item.Center

                // Gleicher weicher Schein wie das Pot-Badge – hier in Gold passend
                // zum Rahmen, damit die Gewinner-Hand ebenso hervorgehoben wird.
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#FFD700"
                    shadowOpacity: 0.45
                    shadowBlur: 0.9
                    shadowVerticalOffset: 0
                }

                Text {
                    id: winHandLabel
                    anchors.centerIn: parent
                    text: (typeof GameTable !== "undefined" && GameTable)
                          ? GameTable.winningHandText : ""
                    color: "#FFD700"
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 14
                    font.bold: true
                }

                // Poppt beim Erscheinen der Gewinner-Hand – analog potPop.
                SequentialAnimation {
                    id: winHandPop
                    NumberAnimation { target: winHandBadge; property: "scale"; from: 1.0; to: 1.18; duration: 110; easing.type: Easing.OutQuad }
                    NumberAnimation { target: winHandBadge; property: "scale"; to: 1.0; duration: 170; easing.type: Easing.OutBack }
                }
                Connections {
                    target: (typeof GameTable !== "undefined") ? GameTable : null
                    function onWinningHandTextChanged() {
                        if (GameTable && GameTable.winningHandText !== "") winHandPop.restart()
                    }
                }
            }

            // ── Gegner-Boxen: auf symmetrische Slots verteilt ────────────────────
            // Sitz 0 (Mensch) sitzt unten in der Mitte; die übrigen besetzten Sitze
            // werden gemäß slotSeq links/rechts ausgewogen verteilt.
            Repeater {
                model: 10
                delegate: Item {
                    id: seatSlot
                    required property int index
                    z: 1

                    readonly property var pdata: (typeof GameTable !== "undefined" && GameTable && GameTable.players.length > index)
                        ? GameTable.players[index] : null
                    readonly property bool occupied: pdata !== null && pdata.name !== ""

                    // Position dieses Sitzes unter den Gegnern (1-basiert; Sitz 0 = Mensch)
                    readonly property int oppOrder: {
                        if (typeof GameTable === "undefined" || !GameTable) return 0
                        var c = 0
                        for (var i = 1; i <= index && i < GameTable.players.length; i++)
                            if (GameTable.players[i].name !== "") c++
                        return c
                    }

                    readonly property int oppCount: tableZone.seatCount - 1
                    readonly property var seq: tableZone.slotSeq[oppCount] || []
                    readonly property string slotName:
                        (occupied && oppOrder >= 1 && oppOrder <= seq.length) ? seq[oppOrder - 1] : ""
                    // Immer ein gültiges [x,y]-Paar liefern. Während eines
                    // Orientierungswechsels (oder vor dem ersten Layout, wenn
                    // width/height noch 0 sind) können slotSeq und slotPos kurz
                    // aus verschiedenen Sätzen stammen → Fallback auf die Mitte,
                    // damit slot[0]/slot[1] nie auf undefined zugreifen.
                    readonly property var slot: {
                        if (slotName === "") return [0.5, 0.5]
                        var p = tableZone.slotPos[slotName]
                        return (p === undefined || p === null) ? [0.5, 0.5] : p
                    }

                    visible: occupied && index !== 0 && slotName !== ""

                    // Inhalt füllt die Box ohne überschüssige Ränder; Karten im
                    // Original-Seitenverhältnis (2×31+3=65)
                    // (4 + Avatar 44 + 4 + Karten 65 + 4 + 4 = 125)
                    width: tableZone.wide ? 125 : 107
                    height: tableZone.oppBaseHeight
                    // Boxen skalieren mit der Auflösung (max = Höhe der Self-Box);
                    // um die Slot-Mitte herum, damit die Position erhalten bleibt.
                    transformOrigin: Item.Center
                    scale: tableZone.oppScale
                    // Hochformat: die Seiten-Boxen als Gruppe vertikal spreizen,
                    // um der Tischmitte mehr Luft zu geben. Untere (Player 1/2/8/9 →
                    // L_lower/L_bottom/R_lower/R_bottom) 14px nach unten, obere
                    // (L_upper/TL/R_upper/TR) 4px nach oben. TC (oben Mitte) bleibt.
                    readonly property real seatNudge: {
                        if (tableZone.wide) return 0
                        if (slotName === "L_lower" || slotName === "L_bottom"
                            || slotName === "R_lower" || slotName === "R_bottom") return 14
                        if (slotName === "L_upper" || slotName === "TL"
                            || slotName === "R_upper" || slotName === "TR") return -4
                        return 0
                    }
                    x: tableZone.width * slot[0] - width / 2
                    y: tableZone.height * slot[1] - height / 2 + seatNudge

                    GamePlayerBox {
                        anchors.fill: parent
                        seatIndex: seatSlot.index
                        // Nur die oberste Box (Player 5, TC-Slot) zeigt das
                        // Winner-Badge im Hochformat unterhalb – sonst überall oben.
                        winnerBelow: !tableZone.wide && seatSlot.slotName === "TC"
                        // Einsatz/Button zur Tischmitte zeigen lassen:
                        // linke Sitze rechts, rechte Sitze links, oben/unten-Mitte unten.
                        // Im breiten (Querformat-)Layout sitzen die oberen Boxen
                        // (Player 4–6) eng im Bogen → Einsatz/Icon unterhalb der Box
                        // anzeigen, damit der seitliche Bereich nicht mit den
                        // Nachbarboxen überlappt.
                        betSide: (seatSlot.slot[1] < 0.30 && tableZone.wide) ? "bottom"
                               : seatSlot.slot[0] < 0.45 ? "right"
                               : seatSlot.slot[0] > 0.55 ? "left"
                               : "bottom"
                    }
                }
            }

            // ── Eigene Box (Sitz 0): unten in der Mitte verankert ────────────────
            GamePlayerSelfBox {
                id: selfBox
                z: 1
                anchors.bottom: parent.bottom
                // Querformat: etwas mehr Luft zwischen Self-Box und Action-Panel
                // (12 px) als unten zum Bildschirmrand (8 px).
                anchors.bottomMargin: tableZone.wide ? 12 : 20
                anchors.horizontalCenter: parent.horizontalCenter
                // Schmaler: Inhalt füllt die Box ohne überschüssige Ränder
                // (6 + Avatar 60 + 6 + Karten [2×43+4=90] + 6 = 168)
                width: tableZone.wide ? 168 : 154
                // Kompakter: keine überschüssige Höhe
                // (4 + Avatar/Karten 60 + 4 + Text 16 + 4 = 88)
                height: tableZone.wide ? 88 : 82
                maxAvatarSize: tableZone.wide ? 60 : 54
            }

            // ── Spielverlauf (Log) + Chat – Umschalt-Icons + Overlays ──────────
            property bool showLog: false
            property bool showChat: false

            // Ungelesene Chat-Nachrichten: alles oberhalb von chatReadCount gilt als
            // ungelesen. Als gelesen markiert wird, sobald der Chat 2 s offen war
            // (chatReadTimer); danach gelten weitere Nachrichten bei offenem Chat
            // sofort als gelesen.
            property int chatReadCount: 0
            readonly property int chatUnread: {
                var n = (typeof GameTable !== "undefined" && GameTable) ? GameTable.chatLog.length : 0
                return Math.max(0, n - chatReadCount)
            }
            onShowChatChanged: {
                if (showChat) chatReadTimer.restart()
                else chatReadTimer.stop()
            }
            Timer {
                id: chatReadTimer
                interval: 2000
                onTriggered: tableZone.chatReadCount =
                    (typeof GameTable !== "undefined" && GameTable) ? GameTable.chatLog.length : 0
            }
            Connections {
                target: (typeof GameTable !== "undefined") ? GameTable : null
                // Bei offenem, bereits gelesenem Chat (2s-Timer abgelaufen) gelten
                // neue Nachrichten sofort als gelesen.
                function onChatLogChanged() {
                    // Chat wurde geleert (neues Spiel) → Zähler nachführen.
                    if (GameTable.chatLog.length < tableZone.chatReadCount)
                        tableZone.chatReadCount = GameTable.chatLog.length
                    if (tableZone.showChat && !chatReadTimer.running)
                        tableZone.chatReadCount = GameTable.chatLog.length
                }
            }

            Item {
                id: logOverlay
                z: 150
                // Querformat/Vollbild: Sidebar (~1/3 Breite) von rechts.
                // Hochformat: volles Overlay über den Tisch.
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: tableZone.wide ? Math.max(parent.width / 3, 300) : parent.width
                visible: tableZone.showLog

                // Schwebendes Sheet: eingerückt, abgerundet, mit Elevation.
                Rectangle {
                    id: logPanel
                    anchors.fill: parent
                    anchors.topMargin: 50   // Abstand zum Umschalt-Icon oben rechts
                    anchors.bottomMargin: 10
                    anchors.leftMargin: tableZone.wide ? 10 : 8
                    anchors.rightMargin: tableZone.wide ? 10 : 8
                    radius: 16
                    color: Config.Theme.withAlpha(Config.StaticData.palette.secondary.col700, 0.95)
                    border.color: Config.StaticData.palette.secondary.col500
                    border.width: 1

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#000000"
                        shadowOpacity: 0.55
                        shadowBlur: 0.9
                        shadowVerticalOffset: 3
                        shadowHorizontalOffset: 0
                    }
                }

                // Klicks innerhalb des Sheets abfangen (Tisch daneben bleibt nutzbar)
                MouseArea { anchors.fill: logPanel }

                ColumnLayout {
                    anchors.fill: logPanel
                    anchors.margins: 12
                    spacing: 8

                    // Header: Titel + Schließen
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Spielverlauf")
                            color: Config.Theme.colorAccent
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: 15
                            font.bold: true
                            font.letterSpacing: 0.4
                        }
                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: 13
                            color: logCloseArea.containsMouse
                                   ? Config.Theme.withAlpha(Config.StaticData.palette.secondary.col500, 0.7)
                                   : "transparent"
                            VectorImage {
                                anchors.centerIn: parent
                                width: 14; height: 14
                                source: "../resources/close.svg"
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: Config.StaticData.palette.secondary.col200
                                }
                            }
                            MouseArea {
                                id: logCloseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: gamePage.toggleLogOverlay()
                            }
                        }
                    }

                    // Trennlinie
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Config.Theme.withAlpha(Config.StaticData.palette.secondary.col500, 0.5)
                    }

                    ListView {
                        id: logList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: (typeof GameTable !== "undefined" && GameTable) ? GameTable.gameLog : []
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}
                        onCountChanged: positionViewAtEnd()
                        delegate: Text {
                            required property var modelData
                            width: ListView.view.width
                            text: modelData
                            // Farben kommen aus dem HTML (Widgets-Log-Style).
                            textFormat: Text.RichText
                            wrapMode: Text.WordWrap
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: 12
                            lineHeight: 1.15
                            bottomPadding: 4
                        }
                    }
                }
            }

            Rectangle {
                id: logToggle
                z: 200
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                width: 34; height: 34; radius: 17
                color: tableZone.showLog ? Config.Theme.colorAccent : Qt.rgba(0, 0, 0, 0.45)

                VectorImage {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "../resources/gameLog.svg"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: tableZone.showLog ? "#101010" : "#FFFFFF"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: gamePage.toggleLogOverlay()
                }
            }

            // ── Chat-Overlay (nur bei menschlichen Mitspielern) ────────────────
            Item {
                id: chatOverlay
                z: 150
                // Querformat/Vollbild: Sidebar (~1/3 Breite) von links.
                // Hochformat: volles Overlay über den Tisch.
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: tableZone.wide ? Math.max(parent.width / 3, 300) : parent.width
                visible: tableZone.showChat
                // Chat geschlossen → Emoji-Picker mitschließen.
                onVisibleChanged: if (!visible) showEmojiPicker = false

                // Emoji-Picker über dem Eingabefeld ein-/ausblenden.
                property bool showEmojiPicker: false
                // Beim Schrumpfen der Liste ans Ende scrollen, damit die letzten
                // Nachrichten sichtbar bleiben.
                onShowEmojiPickerChanged: if (showEmojiPicker) Qt.callLater(chatList.positionViewAtEnd)

                // Chat-History: Pfeil hoch/runter ruft gesendete Nachrichten ab
                // (wie im Qt-Widgets-Client; max. 50 Einträge, Index 1 = letzte).
                property var chatHistory: []
                property int historyIndex: 0
                function showHistory(idx) {
                    if (idx > 0 && idx <= chatHistory.length)
                        chatInput.text = chatHistory[chatHistory.length - idx]
                    else
                        chatInput.text = ""
                    chatInput.cursorPosition = chatInput.text.length
                }

                // Schwebendes Sheet (von links): eingerückt, abgerundet, mit Elevation.
                Rectangle {
                    id: chatPanel
                    anchors.fill: parent
                    anchors.topMargin: 50   // Abstand zum Chat-Icon oben links
                    anchors.bottomMargin: 10
                    anchors.leftMargin: tableZone.wide ? 10 : 8
                    anchors.rightMargin: tableZone.wide ? 10 : 8
                    radius: 16
                    color: Config.Theme.withAlpha(Config.StaticData.palette.secondary.col700, 0.95)
                    border.color: Config.StaticData.palette.secondary.col500
                    border.width: 1

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#000000"
                        shadowOpacity: 0.55
                        shadowBlur: 0.9
                        shadowVerticalOffset: 3
                        shadowHorizontalOffset: 0
                    }
                }

                function chatSend() {
                    if (typeof GameTable === "undefined" || !GameTable) return
                    var t = chatInput.text.trim()
                    if (t.length === 0) return
                    GameTable.sendChat(t)
                    chatHistory.push(chatInput.text)
                    if (chatHistory.length > 50) chatHistory.shift()
                    historyIndex = 0
                    chatInput.text = ""
                }

                // Tab-Vervollständigung: aktuelles Wort zu einem Spielernamen ergänzen.
                function tabComplete() {
                    if (typeof GameTable === "undefined" || !GameTable) return
                    var full = chatInput.text
                    var lastSpace = full.lastIndexOf(" ")
                    var prefix = full.substring(lastSpace + 1)
                    if (prefix.length === 0) return
                    var lower = prefix.toLowerCase()
                    for (var i = 0; i < GameTable.players.length; i++) {
                        var n = GameTable.players[i].name
                        if (n !== "" && n.toLowerCase().indexOf(lower) === 0 && n.toLowerCase() !== lower) {
                            // erstes Wort → mit ": " (Anrede), sonst mit Leerzeichen
                            var suffix = (lastSpace < 0) ? ": " : " "
                            chatInput.text = full.substring(0, lastSpace + 1) + n + suffix
                            chatInput.cursorPosition = chatInput.text.length
                            return
                        }
                    }
                }

                MouseArea { anchors.fill: chatPanel }   // Klicks abfangen

                ColumnLayout {
                    anchors.fill: chatPanel
                    anchors.margins: 12
                    spacing: 8

                    // Header: Titel + Schließen
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Chat")
                            color: Config.Theme.colorAccent
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: 15
                            font.bold: true
                            font.letterSpacing: 0.4
                        }
                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: 13
                            color: chatCloseArea.containsMouse
                                   ? Config.Theme.withAlpha(Config.StaticData.palette.secondary.col500, 0.7)
                                   : "transparent"
                            VectorImage {
                                anchors.centerIn: parent
                                width: 14; height: 14
                                source: "../resources/close.svg"
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: Config.StaticData.palette.secondary.col200
                                }
                            }
                            MouseArea {
                                id: chatCloseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: gamePage.toggleChatOverlay()
                            }
                        }
                    }

                    // Trennlinie
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Config.Theme.withAlpha(Config.StaticData.palette.secondary.col500, 0.5)
                    }

                    ListView {
                        id: chatList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: (typeof GameTable !== "undefined" && GameTable) ? GameTable.chatLog : []
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}
                        onCountChanged: positionViewAtEnd()
                        spacing: 3
                        delegate: Item {
                            required property var modelData
                            width: ListView.view.width
                            implicitHeight: bubble.height

                            Rectangle {
                                id: bubble
                                width: parent.width
                                height: msgText.implicitHeight + 6
                                radius: 8
                                color: Config.Theme.withAlpha(Config.StaticData.palette.secondary.col600, 0.55)

                                Text {
                                    id: msgText
                                    anchors {
                                        left: parent.left; right: parent.right; top: parent.top
                                        leftMargin: 8; rightMargin: 8; topMargin: 3
                                    }
                                    text: modelData
                                    textFormat: Text.RichText
                                    wrapMode: Text.WordWrap
                                    color: Config.StaticData.palette.secondary.col100
                                    font.family: Config.StaticData.loadedFont.font.family
                                    font.pixelSize: 12
                                    lineHeight: 1.0
                                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                                }
                            }
                        }
                    }

                    // Emoji-Picker – über dem Eingabefeld; die Nachrichtenliste
                    // (Layout.fillHeight) schrumpft entsprechend, letzte Nachrichten
                    // bleiben sichtbar.
                    EmojiPicker {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        visible: chatOverlay.showEmojiPicker
                        onPicked: (emoji) => {
                            chatInput.insert(chatInput.cursorPosition, emoji)
                            chatInput.forceActiveFocus()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        // Emoji-Picker-Umschalter
                        Button {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            onClicked: chatOverlay.showEmojiPicker = !chatOverlay.showEmojiPicker
                            background: Rectangle {
                                radius: 6
                                color: chatOverlay.showEmojiPicker
                                       ? Config.StaticData.palette.secondary.col500 : "transparent"
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            contentItem: Text {
                                text: "🙂"
                                font.family: Config.StaticData.emojiFamily
                                font.pixelSize: 20
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        TextField {
                            id: chatInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("Nachricht …")
                            font.family: Config.StaticData.loadedFont.font.family
                            color: Config.StaticData.palette.secondary.col100
                            placeholderTextColor: Config.StaticData.palette.secondary.col400
                            background: Rectangle {
                                radius: 6
                                color: Config.StaticData.palette.secondary.col600
                                border.color: chatInput.activeFocus
                                    ? Config.StaticData.palette.secondary.col200
                                    : Config.StaticData.palette.secondary.col400
                                border.width: 1
                            }
                            onAccepted: chatOverlay.chatSend()
                            Keys.onReturnPressed: chatOverlay.chatSend()
                            // Tippt der Nutzer, History-Navigation zurücksetzen.
                            onTextEdited: chatOverlay.historyIndex = 0
                            // Tab = Namens-Vervollständigung; Hoch/Runter = History.
                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Tab) {
                                    event.accepted = true
                                    chatOverlay.tabComplete()
                                } else if (event.key === Qt.Key_Up) {
                                    event.accepted = true
                                    if (chatOverlay.historyIndex + 1 <= chatOverlay.chatHistory.length)
                                        chatOverlay.historyIndex++
                                    chatOverlay.showHistory(chatOverlay.historyIndex)
                                } else if (event.key === Qt.Key_Down) {
                                    event.accepted = true
                                    if (chatOverlay.historyIndex - 1 >= 0)
                                        chatOverlay.historyIndex--
                                    chatOverlay.showHistory(chatOverlay.historyIndex)
                                }
                            }
                        }
                        // Senden-Button wie in der Lobby (send.svg)
                        Button {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 36
                            enabled: chatInput.text.trim().length > 0
                            onClicked: chatOverlay.chatSend()
                            background: Item {}
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            contentItem: Image {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: "../resources/send.svg"
                                sourceSize: Qt.size(36, 36)
                                smooth: true
                                antialiasing: true
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: Config.Theme.colorChatSend
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: chatToggle
                z: 200
                visible: (typeof GameTable !== "undefined" && GameTable) ? GameTable.hasHumanOpponents : false
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 8
                width: 34; height: 34; radius: 17
                color: tableZone.showChat ? Config.Theme.colorAccent : Qt.rgba(0, 0, 0, 0.45)

                VectorImage {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "../resources/gameChat.svg"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: tableZone.showChat ? "#101010" : "#FFFFFF"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: gamePage.toggleChatOverlay()
                }

                // Badge mit Anzahl ungelesener Chat-Nachrichten.
                Rectangle {
                    visible: tableZone.chatUnread > 0
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -3
                    anchors.rightMargin: -3
                    width: Math.max(17, unreadLabel.implicitWidth + 8)
                    height: 17
                    radius: 8.5
                    color: Config.Theme.colorDanger
                    border.color: "#1d222b"
                    border.width: 1.5

                    Text {
                        id: unreadLabel
                        anchors.centerIn: parent
                        text: tableZone.chatUnread > 99 ? "99+" : tableZone.chatUnread
                        color: "#FFFFFF"
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
        }

        // 3. Action-Leiste: Raise-Controls + Fold / Call / Raise
        Item {
            id: actionBar
            Layout.fillWidth: true
            // Höhe wächst dynamisch mit dem Inhalt (Querformat: +8 px, damit das
            // Panel mit 8 px Abstand über dem unteren Bildschirmrand schwebt).
            Layout.preferredHeight: actionBarCol.implicitHeight + (tableZone.wide ? 8 : 0)

            // Querformat: Inhalt auf die (skalierte) Breite des Community-Cards-
            // Bereichs begrenzen und zentrieren – sonst wird u. a. der Slider viel
            // zu breit. Eine Untergrenze stellt sicher, dass die Steuerelemente
            // (Pot-Buttons + All-In + Spielmodus) nicht zu eng werden. Hochformat:
            // volle Breite.
            readonly property real panelWidth: tableZone.wide
                ? Math.min(width, Math.max(communityArea.width * communityArea.scale, 380))
                : width

            // Aktuell vorbereiteter Raise-Betrag; kann auch vor dem eigenen Zug gesetzt werden
            property int raiseAmount: 0

            readonly property bool raiseAvailable: GameTable !== null
                                                   && GameTable.maxRaiseAmount > 0
                                                   && GameTable.minRaiseAmount > 0
            readonly property int raiseMinAmount: raiseAvailable ? GameTable.minRaiseAmount : 0
            readonly property int raiseMaxAmount: raiseAvailable ? GameTable.maxRaiseAmount : 0

            // Dynamische Button-Beschriftungen – analog zum Qt-Widgets-Client:
            //  • nichts zu callen  → "Check"      sonst → "Call $X"
            //  • Preflop oder schon gesetzt → "Raise $X"; postflop ohne Einsatz → "Bet $X"
            readonly property bool canCheck: GameTable !== null && GameTable.callAmount === 0
            readonly property bool isPreflop: GameTable !== null && GameTable.phaseText === "Preflop"
            readonly property string checkCallText: GameTable === null ? qsTr("Call")
                : (canCheck ? qsTr("Check") : qsTr("Call") + "\n$" + GameTable.callAmount)
            readonly property string betRaiseText: {
                if (GameTable === null) return qsTr("Raise")
                var word = (!isPreflop && canCheck) ? qsTr("Bet") : qsTr("Raise")
                return raiseAvailable ? (word + "\n$" + raiseAmount) : word
            }

            // ── Vorwahl (pre-selection): vor dem eigenen Zug eine Aktion vormerken ──
            property string preAction: ""        // "", "fold", "call", "raise", "allin"
            property int preCallAmount: -1        // callAmount zum Zeitpunkt der Vorwahl
            // Spielmodus: 0 = manuell, 1 = Auto Check/Call, 2 = Auto Check/Fold.
            property int playingMode: 0

            readonly property bool canAct: GameTable !== null && GameTable.canAct
            // Während der Vorwahl zeigt der Fold-Button bei freiem Check "Check / Fold"
            // Vorwahl bei gratis Check: zweizeilig, damit auch längere Übersetzungen
            // (z. B. "Check / Se coucher") auf den Button passen.
            readonly property string foldText: (GameTable !== null && !GameTable.myTurn && canCheck)
                ? (qsTr("Check") + " /\n" + qsTr("Fold")) : qsTr("Fold")

            function fireAction(which) {
                if (GameTable === null) return
                if (which === "fold")       GameTable.fold()
                else if (which === "call")  GameTable.call()
                else if (which === "raise") GameTable.raise(raiseAmount)
                else if (which === "allin") GameTable.allIn()
            }

            // Vorgemerkte Aktion beim eigenen Zug ausführen.
            // Vorgemerktes "Fold" wird zu "Check", falls ein Check gratis möglich ist.
            function runPreAction(which) {
                if (which === "fold" && canCheck) GameTable.call()
                else fireAction(which)
            }

            function clickAction(which) {
                if (GameTable === null) return
                // Eigener Klick auf einen Action-Button hat Vorrang vor dem
                // Auto-Modus → zurück auf "manuell", dann die Aktion ausführen
                // bzw. vormerken (wie im Qt-Widgets-Client).
                if (playingMode !== 0)
                    playingMode = 0
                if (GameTable.myTurn) {
                    preAction = ""
                    fireAction(which)
                } else if (canAct) {
                    if (preAction === which) {
                        preAction = ""
                    } else {
                        preAction = which
                        preCallAmount = (which === "call") ? GameTable.callAmount : -1
                    }
                }
            }

            function raiseStepFor(maximum) {
                if (maximum <= 1000)
                    return 10
                if (maximum <= 10000)
                    return 50
                if (maximum <= 100000)
                    return 500
                return 5000
            }

            function roundedRaiseAmount(amount) {
                if (!raiseAvailable)
                    return 0
                if (amount >= raiseMaxAmount)
                    return raiseMaxAmount
                var step = raiseStepFor(raiseMaxAmount)
                return Math.floor(amount / step) * step
            }

            function clampRaiseAmount(amount) {
                if (!raiseAvailable)
                    return 0
                return Math.max(raiseMinAmount, Math.min(raiseMaxAmount, amount))
            }

            function syncRaiseAmount() {
                if (!raiseAvailable) {
                    raiseAmount = 0
                    return
                }
                if (raiseAmount <= 0)
                    raiseAmount = raiseMinAmount
                else
                    raiseAmount = clampRaiseAmount(roundedRaiseAmount(raiseAmount))
            }

            // Raise-Wert vorbereiten, Vorwahl ausführen bzw. bei Änderungen verwerfen
            Connections {
                target: GameTable
                function onMyTurnChanged() {
                    actionBar.syncRaiseAmount()
                    if (!GameTable.myTurn)
                        return
                    // Auto-Spielmodus hat Vorrang vor der manuellen Vorwahl.
                    // SYNCHRON ausführen (nicht via Qt.callLater): diese Funktion
                    // läuft als Reaktion auf das myTurnChanged-Signal der Engine,
                    // nicht in einem QML-Eingabe-Event – ein erneutes myTurnChanged
                    // aus doActionDone (setzt myTurn=false) kehrt hier sofort wieder
                    // zurück, also keine Re-Entrancy-Gefahr. Verzögert hingegen
                    // konnte eine zwischenzeitliche Nachricht (disableMyButtons →
                    // myTurn=false) die Aktion verschlucken → Timeout statt Aktion.
                    if (actionBar.playingMode === 2 || actionBar.playingMode === 1) {
                        gamePage.runAutoAction()
                    } else if (actionBar.preAction !== "") {       // Manuell: Vorwahl ausführen
                        var a = actionBar.preAction
                        actionBar.preAction = ""
                        actionBar.runPreAction(a)
                    }
                }
                function onCallAmountChanged() {
                    // Sicherheit: vorgemerkter Call/Check verfällt, wenn sich der Call-Betrag ändert
                    if (actionBar.preAction === "call" && GameTable.callAmount !== actionBar.preCallAmount)
                        actionBar.preAction = ""
                    actionBar.syncRaiseAmount()
                }
                function onMinRaiseAmountChanged() {
                    if (actionBar.preAction === "raise" && !actionBar.raiseAvailable)
                        actionBar.preAction = ""
                    actionBar.syncRaiseAmount()
                }
                function onMaxRaiseAmountChanged() {
                    if (actionBar.preAction === "raise" && !actionBar.raiseAvailable)
                        actionBar.preAction = ""
                    actionBar.syncRaiseAmount()
                }
                function onCanActChanged() {
                    // Kann nicht mehr agieren (gefoldet/all-in) → Vorwahl löschen
                    if (!GameTable.canAct)
                        actionBar.preAction = ""
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                // Querformat: 8 px Abstand zum unteren Bildschirmrand (Tisch zeigt
                // sich darunter durch).
                anchors.bottomMargin: tableZone.wide ? 8 : 0
                anchors.horizontalCenter: parent.horizontalCenter
                width: actionBar.panelWidth
                color: Qt.rgba(0, 0, 0, 0.82)
                // Geschrumpft (Querformat) als leicht abgerundetes Panel.
                radius: tableZone.wide ? 10 : 0
            }

            Column {
                id: actionBarCol
                width: actionBar.panelWidth
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                // ── Raise-Bereich: dauerhaft vorbereitbar, Aktion erst beim eigenen Zug ──
                Column {
                    id: raiseSection
                    width: parent.width
                    spacing: 4
                    topPadding: 5
                    bottomPadding: 3
                    leftPadding: 8
                    rightPadding: 8
                    visible: GameTable !== null
                    height: visible ? implicitHeight : 0
                    clip: true

                    // Zeile 1: Betrag-Eingabe (links) + Slider
                    RowLayout {
                        width: parent.width - 16
                        spacing: 6

                        // Betrag-Eingabe – links neben dem Slider
                        Rectangle {
                            Layout.preferredWidth: 78
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignVCenter
                            radius: 5
                            color: actionBar.raiseAvailable ? "#1a2a1a" : "#171717"
                            border.color: actionBar.raiseAvailable ? "#4CAF50" : "#3a3a3a"
                            border.width: 1
                            TextInput {
                                id: raiseAmountInput
                                anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                                enabled: actionBar.raiseAvailable
                                text: actionBar.raiseAmount.toString()
                                color: enabled ? "#FFFFFF" : "#8a8a8a"
                                font.family: Config.StaticData.loadedFont.font.family
                                font.pixelSize: 13
                                font.bold: true
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator { bottom: 0; top: 9999999 }
                                onAccepted: {
                                    var v = parseInt(text)
                                    if (!isNaN(v) && GameTable) {
                                        actionBar.raiseAmount = actionBar.clampRaiseAmount(v)
                                    }
                                }
                                // Text bleibt synchron mit raiseAmount (von Slider/%-Buttons)
                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        text = actionBar.raiseAmount.toString()
                                    }
                                }
                                Connections {
                                    target: actionBar
                                    function onRaiseAmountChanged() {
                                        if (!raiseAmountInput.activeFocus)
                                            raiseAmountInput.text = actionBar.raiseAmount.toString()
                                    }
                                }
                            }
                        }

                        Slider {
                            id: raiseSlider
                            Layout.fillWidth: true
                            Layout.preferredHeight: 26
                            Layout.alignment: Qt.AlignVCenter
                            enabled: actionBar.raiseAvailable
                            opacity: enabled ? 1.0 : 0.45
                            from: actionBar.raiseMinAmount
                            to: actionBar.raiseAvailable ? Math.max(actionBar.raiseMinAmount, actionBar.raiseMaxAmount) : 1
                            stepSize: actionBar.raiseStepFor(actionBar.raiseMaxAmount)
                            value: actionBar.raiseAmount
                            onMoved: actionBar.raiseAmount = actionBar.clampRaiseAmount(actionBar.roundedRaiseAmount(value))

                            background: Rectangle {
                                x: raiseSlider.leftPadding
                                y: raiseSlider.topPadding + raiseSlider.availableHeight / 2 - height / 2
                                width: raiseSlider.availableWidth
                                height: 4
                                radius: 2
                                color: "#333333"
                                Rectangle {
                                    width: raiseSlider.visualPosition * parent.width
                                    height: parent.height
                                    radius: 2
                                    color: "#4CAF50"
                                }
                            }
                            handle: Rectangle {
                                x: raiseSlider.leftPadding + raiseSlider.visualPosition * (raiseSlider.availableWidth - width)
                                y: raiseSlider.topPadding + raiseSlider.availableHeight / 2 - height / 2
                                width: 18; height: 18; radius: 9
                                color: raiseSlider.pressed ? "#80FF80" : "#4CAF50"
                                border.color: "#2a7a2a"
                                border.width: 1
                            }
                        }
                    }

                    // Zeile 2: Pot-%-Buttons + All-In (bündig) + Spielmodus-Dropdown (rechts)
                    RowLayout {
                        width: parent.width - 16
                        spacing: 4

                        // Pot-Prozent-Buttons: 1/3 · 1/2 · Pot
                        Repeater {
                            model: [
                                { label: "1/3", frac: 1.0 / 3.0 },
                                { label: "1/2", frac: 0.5 },
                                { label: "Pot", frac: 1.0 }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                visible: SettingsManager
                                         ? SettingsManager.readConfigInt("ShowPotPercentButtons") !== 0
                                         : true
                                Layout.preferredWidth: visible ? 38 : 0
                                Layout.preferredHeight: 28
                                radius: 5
                                enabled: actionBar.raiseAvailable
                                color: !enabled ? "#202020" : potBtnArea.containsPress ? "#2e7d32" : potBtnArea.containsMouse ? "#388e3c" : "#1b5e20"
                                border.color: enabled ? "#4CAF50" : "#3a3a3a"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: parent.enabled ? "#FFFFFF" : "#8a8a8a"
                                    font.family: Config.StaticData.loadedFont.font.family
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                MouseArea {
                                    id: potBtnArea
                                    anchors.fill: parent
                                    cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    hoverEnabled: parent.enabled
                                    enabled: parent.enabled
                                    onClicked: {
                                        if (!GameTable || !actionBar.raiseAvailable) return
                                        var tp = GameTable.totalPot
                                        var tgt = Math.round(tp * modelData.frac)
                                        actionBar.raiseAmount = actionBar.clampRaiseAmount(tgt)
                                    }
                                }
                            }
                        }

                        // All-In – bündig an die Pot-Buttons
                        Rectangle {
                            id: allInBtn
                            readonly property bool preChecked: actionBar.preAction === "allin"
                            Layout.preferredWidth: 52
                            Layout.preferredHeight: 28
                            radius: 5
                            opacity: actionBar.canAct ? 1.0 : 0.4
                            color: allInArea.containsPress ? Qt.lighter(Config.Theme.colorAllInBottom, 1.35)
                                 : allInArea.containsMouse ? Config.Theme.colorAllInTop
                                 : Config.Theme.colorAllInBottom
                            border.color: allInBtn.preChecked ? "#FFD700" : Config.Theme.colorAllInEdge
                            border.width: allInBtn.preChecked ? 2 : 1
                            scale: (allInArea.pressed && actionBar.canAct) ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                            Text {
                                anchors.centerIn: parent
                                text: qsTr("All-In")
                                color: "#FFFFFF"
                                font.family: Config.StaticData.loadedFont.font.family
                                font.pixelSize: 12
                                font.bold: true
                            }
                            MouseArea {
                                id: allInArea
                                anchors.fill: parent
                                enabled: actionBar.canAct
                                cursorShape: actionBar.canAct ? Qt.PointingHandCursor : Qt.ArrowCursor
                                hoverEnabled: true
                                onClicked: actionBar.clickAction("allin")
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Spielmodus-Dropdown (rechts): Manuell / Auto Check/Call / Auto Check/Fold
                        ComboBox {
                            id: playingModeCombo
                            Layout.preferredWidth: 132
                            Layout.preferredHeight: 28
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: 11
                            model: [ qsTr("Manuell"), qsTr("Auto Check/Call"), qsTr("Auto Check/Fold") ]
                            currentIndex: actionBar.playingMode
                            onActivated: (index) => gamePage.applyPlayingMode(index)

                            contentItem: Text {
                                leftPadding: 8
                                rightPadding: playingModeCombo.indicator.width + 4
                                text: playingModeCombo.displayText
                                font: playingModeCombo.font
                                color: "#FFFFFF"
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            background: Rectangle {
                                radius: 5
                                color: actionBar.playingMode === 0 ? "#222222" : "#3a2e10"
                                border.color: actionBar.playingMode === 0 ? "#3a3a3a" : Config.Theme.colorAccent
                                border.width: 1
                            }
                        }
                    }
                }

                // ── Aktions-Buttons: Fold / Check-Call / Bet-Raise ────────────────
                // Dynamische Beschriftung + Aktivierung wie im Qt-Widgets-Client.
                Item {
                    width: parent.width
                    // Touch-freundlich: auf schmalen (mobilen) Fenstern höher, damit
                    // die Buttons gut in der Daumenzone liegen.
                    height: Config.Theme.compact ? 64 : 54

                    // Wiederverwendbarer Aktions-Button mit Verlauf, dynamischem Text und
                    // Vorwahl-Zustand (goldener Rahmen = vorgemerkt).
                    component ActionButton: Rectangle {
                        id: ab
                        property string actionKey: ""
                        property string label: ""
                        property color topColor: "#4080d8"
                        property color bottomColor: "#1a3d8b"
                        property color edgeColor: "#6aa0e8"
                        property bool armed: false   // klickbar: eigener Zug ODER Vorwahl möglich
                        property bool highlight: false   // primäre Aktion hervorheben (Raise)
                        readonly property bool myTurnNow: GameTable !== null && GameTable.myTurn
                        readonly property bool preChecked: ab.actionKey !== "" && actionBar.preAction === ab.actionKey

                        radius: 9
                        border.width: (ab.preChecked || (ab.highlight && ab.armed)) ? 2 : 1
                        border.color: ab.preChecked ? "#FFD700" : (ab.armed ? edgeColor : "#3a3a3a")
                        opacity: !ab.armed ? 0.4 : ((ab.myTurnNow || ab.preChecked) ? 1.0 : 0.72)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: ab.armed ? ab.topColor : "#2b2b2b" }
                            GradientStop { position: 1.0; color: ab.armed ? ab.bottomColor : "#1c1c1c" }
                        }

                        // Press-Feedback: kurzes Einsinken beim Tippen.
                        scale: (abMouse.pressed && ab.armed) ? 0.96 : 1.0
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

                        // Raise als primäre Aktion mit weichem Glow hervorheben.
                        layer.enabled: ab.highlight && ab.armed
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: ab.edgeColor
                            shadowOpacity: 0.55
                            shadowBlur: 0.8
                            shadowVerticalOffset: 0
                            shadowHorizontalOffset: 0
                        }

                        Text {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: ab.label
                            color: "#F0F0F0"
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: 15
                            font.bold: true
                            font.letterSpacing: 0.5
                            lineHeight: 0.95
                        }

                        // kleiner "vorgemerkt"-Punkt oben rechts
                        Rectangle {
                            visible: ab.preChecked
                            anchors { top: parent.top; right: parent.right; margins: 4 }
                            width: 8; height: 8; radius: 4
                            color: "#FFD700"
                        }

                        MouseArea {
                            id: abMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: ab.armed
                            cursorShape: ab.armed ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: actionBar.clickAction(ab.actionKey)
                        }
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 5
                                  bottomMargin: Config.Theme.compact ? 9 : 5 }
                        spacing: 8

                        ActionButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            actionKey: "fold"
                            label: actionBar.foldText
                            topColor: Config.Theme.colorFoldTop
                            bottomColor: Config.Theme.colorFoldBottom
                            edgeColor: Config.Theme.colorFoldEdge
                            armed: actionBar.canAct
                        }

                        ActionButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            actionKey: "call"
                            label: actionBar.checkCallText
                            topColor: Config.Theme.colorCallTop
                            bottomColor: Config.Theme.colorCallBottom
                            edgeColor: Config.Theme.colorCallEdge
                            armed: actionBar.canAct
                        }

                        ActionButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            actionKey: "raise"
                            label: actionBar.betRaiseText
                            topColor: Config.Theme.colorRaiseTop
                            bottomColor: Config.Theme.colorRaiseBottom
                            edgeColor: Config.Theme.colorRaiseEdge
                            highlight: true     // primäre Aktion betonen
                            armed: actionBar.canAct && actionBar.raiseAvailable
                        }
                    }
                }
            }
        }
    }
}
