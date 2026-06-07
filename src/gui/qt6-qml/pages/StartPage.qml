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

    readonly property bool denseLayout: Config.Responsive.landscapeCompact
    readonly property bool isLandscape: width > height
    readonly property real buttonHeight: denseLayout ? 30 : Config.Theme.touchTarget
    readonly property real outerMargin:  denseLayout ? 4  : Config.Theme.margin
    readonly property real innerSpacing: denseLayout ? 4  : Config.Theme.spacing

    // Logo-Größe passt sich dem verfügbaren vertikalen Platz an, damit
    // Landscape-Modus nie vertikal scrollt.
    readonly property real logoSize: {
        if (denseLayout)                 return 50   // Phone-Landscape (landscapeCompact)
        if (isLandscape)                 return 80   // reguläres Landscape (Tablet/Desktop)
        if (Config.Responsive.compact)   return 110  // Portrait-Phone
        return 140                                   // Portrait Desktop/Tablet
    }
    readonly property real logoSpacing: denseLayout ? 6 : isLandscape ? 12 : 20

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
                                     startPageMainButtonsBox.height + startPage.outerMargin * 2)

            // ── Overlay-Box: enthält Logo + Navigations-Buttons ──────────────
            Rectangle {
                id: startPageMainButtonsBox
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(startContent.width - startPage.outerMargin * 2, 320)
                height: startBoxContent.implicitHeight + startPage.outerMargin * 2
                color: "transparent"

                // Halb-transparenter Hintergrund über dem gesamten Bereich
                Rectangle {
                    anchors.fill: parent
                    color: Config.StaticData.palette.secondary.col700
                    opacity: 0.8
                    radius: 5
                }

                Column {
                    id: startBoxContent
                    anchors {
                        left: parent.left; right: parent.right; top: parent.top
                        margins: startPage.outerMargin
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
