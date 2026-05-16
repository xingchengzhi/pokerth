import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

import "../config" as Config
import "../components"

Rectangle {
    id: resetSettings
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    color: "transparent"

    property bool resetDone: false

    ColumnLayout {
        id: resetSettingsContent
        anchors.fill: parent

        Label {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 8
            Layout.bottomMargin: 0
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.fillHeight: false
            horizontalAlignment: Text.AlignLeft
            text: qsTr("Standardeinstellung")
            font.bold: true
            font.pointSize: 12
            color: Config.StaticData.palette.secondary.col200
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.fillHeight: false
            Layout.topMargin: 0
            Layout.bottomMargin: 4
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.alignment: Qt.AlignTop
            color: Config.StaticData.palette.secondary.col500
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width
                spacing: 16

                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: qsTr("Alle Einstellungen werden auf die Standardwerte zurückgesetzt. Diese Aktion kann nicht rückgängig gemacht werden.")
                    wrapMode: Text.Wrap
                    color: Config.StaticData.palette.secondary.col200
                    font.pointSize: 11
                }

                CustomButton {
                    id: resetButton
                    text: qsTr("Auf Werkeinstellungen zurücksetzen")
                    enabled: !resetSettings.resetDone
                    Layout.topMargin: 4
                    implicitWidth: contentItem.implicitWidth + 24

                    background: Rectangle {
                        radius: Config.Theme.radiusSmall
                        color: resetButton.enabled
                               ? (resetButton.pressed
                                  ? "#7f1010"
                                  : resetButton.hovered
                                    ? "#c0392b"
                                    : "#922b21")
                               : Config.StaticData.palette.secondary.col600
                        border.color: resetButton.enabled
                                      ? (resetButton.hovered || resetButton.pressed ? "#ff6b6b" : "#e74c3c")
                                      : Config.StaticData.palette.secondary.col500
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    onClicked: {
                        if (SettingsManager) {
                            SettingsManager.resetToDefaults()
                            resetSettings.resetDone = true
                        }
                    }
                }

                Label {
                    visible: resetSettings.resetDone
                    Layout.fillWidth: true
                    text: qsTr("Einstellungen wurden zurückgesetzt. Bitte starte PokerTH neu, damit alle Änderungen wirksam werden.")
                    wrapMode: Text.Wrap
                    color: "#2ecc71"
                    font.pointSize: 11
                }
            }
        }
    }
}
