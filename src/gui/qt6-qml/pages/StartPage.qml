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

    ColumnLayout {
        id: startPageRows
        anchors.fill: parent

        ColumnLayout {
            id: startPageContentLayout
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: startPageMainButtonsBox
                Layout.alignment:   Qt.AlignHCenter
                Layout.fillWidth:   true
                Layout.maximumWidth: 320
                Layout.leftMargin:  Config.Theme.margin
                Layout.rightMargin: Config.Theme.margin
                // Height grows with content
                Layout.preferredHeight: startPageMainButtons.implicitHeight + Config.Theme.margin * 2
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
                        margins: Config.Theme.margin
                    }
                    spacing: Config.Theme.spacing

                    CustomButton {
                        text: qsTr("Internetspiel")
                        Layout.fillWidth: true
                        onClicked: mainStackView.push("ServerConnectionDialog.qml")
                    }

                    CustomButton {
                        text: qsTr("Lokales Spiel starten")
                        Layout.fillWidth: true
                        onClicked: mainStackView.push("LocalGamePage.qml")
                    }

                    CustomButton {
                        text: qsTr("Netzwerkspiel erstellen")
                        Layout.fillWidth: true
                        onClicked: mainStackView.push("NetworkGameCreatePage.qml")
                    }

                    CustomButton {
                        text: qsTr("Netzwerkspiel beitreten")
                        Layout.fillWidth: true
                        onClicked: mainStackView.push("NetworkGameEnterPage.qml")
                    }

                    CustomButton {
                        text: qsTr("Logs")
                        Layout.fillWidth: true
                        onClicked: mainStackView.push("LogsPage.qml")
                    }
                }
            }
        }
    }
}
