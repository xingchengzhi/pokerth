import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

import "../config" as Config
import "../components"

Rectangle {
    id: localGamePagePage
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: Config.StaticData.palette.secondary.col700

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Config.Theme.margin
        spacing: Config.Theme.spacing

        Label {
            text: qsTr("Lokales Spiel")
            font.family: Config.StaticData.loadedFont.font.family
            font.bold: true
            font.pixelSize: 16
            color: Config.StaticData.palette.secondary.col200
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Config.StaticData.palette.secondary.col500
        }

        Item { Layout.fillHeight: true }

        CustomButton {
            text: qsTr("Spiel starten")
            Layout.fillWidth: true
            onClicked: {
                GameTable.startLocalGame()
                mainStackView.push("GamePage.qml")
            }
        }

        Item { Layout.fillHeight: true }
    }
}
