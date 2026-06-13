import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.VectorImage

import "../config" as Config
import "../components"

Rectangle {
    id: startPage
    width: mainWindow.width
    height: mainWindow.height
    color: "transparent"

    Image {
        id: preLoaderBackground
        anchors.fill: parent
        source: "../resources/startWindowBackground.png"
        fillMode: Image.PreserveAspectCrop
    }

    readonly property bool isLandscape: width > height
    // denseLayout nur für echte Mobilgeräte (logische Höhe < 500px = Phone-Landscape).
    // HiDPI-Desktops haben dort höhere logische Höhen trotz kleiner physischer Pixelzahl.
    readonly property bool denseLayout: Config.Responsive.landscapeCompact && height < 500

    // Horizontal padding inside box (fixed — keeps buttons wide enough for text)
    readonly property real hPad: denseLayout ? 4 : 20
    // Vertical padding inside box (scales with window height)
    readonly property real vPad: {
        if (denseLayout)   return 4
        if (isLandscape)   return Math.max(14, Math.min(40, height * 0.034))
        return Config.Theme.margin
    }
    readonly property real buttonHeight: {
        if (denseLayout)   return 30
        if (isLandscape)   return Math.max(42, Math.min(84, height * 0.075))
        return Config.Theme.touchTarget
    }
    readonly property real innerSpacing: {
        if (denseLayout)   return 4
        if (isLandscape)   return Math.max(8, Math.min(26, height * 0.024))
        return Config.Theme.spacing
    }

    // Logo-Größe passt sich dem verfügbaren vertikalen Platz an, damit
    // Landscape-Modus nie vertikal scrollt.
    readonly property real logoSize: {
        if (denseLayout)                 return 50   // Phone-Landscape (landscapeCompact)
        if (isLandscape)                 return Math.max(60, Math.min(130, height * 0.13))
        if (Config.Responsive.compact)   return 110  // Portrait-Phone
        return 140                                   // Portrait Desktop/Tablet
    }
    readonly property real logoSpacing: {
        if (denseLayout)   return 6
        if (isLandscape)   return Math.max(10, Math.min(32, height * 0.028))
        return 20
    }

    Flickable {
        id: startScroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: startContent.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: startContent
            width: startScroll.width
            // Mindesthöhe = Viewport → Inhalt bleibt vertikal zentriert,
            // solange er passt. Landscape-Logos sind klein genug, dass
            // implicitHeight immer ≤ startScroll.height bleibt.
            implicitHeight: Math.max(startScroll.height,
                                     startPageMainButtonsBox.height + startPage.vPad * 2)

            // ── Overlay-Box: enthält Logo + Navigations-Buttons ──────────────
            Rectangle {
                id: startPageMainButtonsBox
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(startContent.width - startPage.hPad * 2, 380)
                height: startBoxContent.implicitHeight + startPage.vPad * 2
                color: "transparent"

                // Dunkler Hintergrund – immer dunkel damit der Kontrast zum Feuer-
                // Hintergrund stimmt, unabhängig vom Hell/Dunkel-Theme.
                Rectangle {
                    anchors.fill: parent
                    color: "#1d222b"
                    opacity: 0.88
                    radius: 5
                }

                Column {
                    id: startBoxContent
                    anchors {
                        left: parent.left; right: parent.right; top: parent.top
                        leftMargin: startPage.hPad
                        rightMargin: startPage.hPad
                        topMargin: startPage.vPad
                    }
                    spacing: startPage.logoSpacing

                    // ── PokerTH-Logo ─────────────────────────────────────────
                    VectorImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:  startPage.logoSize
                        height: startPage.logoSize
                        source: "../resources/pokerth.svg"
                    }

                    // ── Navigations-Buttons ───────────────────────────────────
                    ColumnLayout {
                        id: startPageMainButtons
                        width: parent.width
                        spacing: startPage.innerSpacing

                        CustomButton {
                            text: qsTr("Internetspiel")
                            Layout.fillWidth: true
                            Layout.preferredHeight: startPage.buttonHeight
                            onClicked: mainStackView.push("ServerConnectionDialog.qml")
                        }

                        CustomButton {
                            text: qsTr("Lokales Spiel starten")
                            Layout.fillWidth: true
                            Layout.preferredHeight: startPage.buttonHeight
                            onClicked: mainStackView.push("LocalGamePage.qml")
                        }

                        CustomButton {
                            text: qsTr("Netzwerkspiel erstellen")
                            Layout.fillWidth: true
                            Layout.preferredHeight: startPage.buttonHeight
                            onClicked: mainStackView.push("NetworkGameCreatePage.qml")
                        }

                        CustomButton {
                            text: qsTr("Netzwerkspiel beitreten")
                            Layout.fillWidth: true
                            Layout.preferredHeight: startPage.buttonHeight
                            onClicked: mainStackView.push("NetworkGameEnterPage.qml")
                        }

                        CustomButton {
                            text: qsTr("Logs")
                            Layout.fillWidth: true
                            Layout.preferredHeight: startPage.buttonHeight
                            onClicked: mainStackView.push("LogsPage.qml")
                        }
                    }
                }
            }
        }
    }
}
