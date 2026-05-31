import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

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

    // Im landscapeCompact (Phone-Landscape) müssen die Buttons in das knappe
    // vertikale Budget passen – Höhe / Padding gehen runter, und die ganze
    // Sektion wird in einen Flickable gesteckt, falls trotzdem mal Inhalt
    // überläuft (z. B. wenn Sprach-Strings länger sind als auf Deutsch).
    readonly property bool denseLayout: Config.Responsive.landscapeCompact
    readonly property real buttonHeight: denseLayout ? 30 : Config.Theme.touchTarget
    readonly property real outerMargin:  denseLayout ? 4  : Config.Theme.margin
    readonly property real innerSpacing: denseLayout ? 4  : Config.Theme.spacing

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
            // Mindesthöhe = Viewport, damit der Inhalt vertikal zentriert
            // bleibt solange er reinpasst.
            implicitHeight: Math.max(startScroll.height, startPageMainButtonsBox.height + startPage.outerMargin * 2)

            Rectangle {
                id: startPageMainButtonsBox
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(parent.width - startPage.outerMargin * 2, 320)
                height: startPageMainButtons.implicitHeight + startPage.outerMargin * 2
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: Config.StaticData.palette.secondary.col700
                    opacity: 0.8
                    radius: 5
                }

                ColumnLayout {
                    id: startPageMainButtons
                    anchors {
                        left: parent.left; right: parent.right; top: parent.top
                        margins: startPage.outerMargin
                    }
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
