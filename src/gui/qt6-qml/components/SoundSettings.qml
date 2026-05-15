import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

import "../config" as Config

Rectangle {
    id: soundSettings
    //Layout.preferredWidth: parent.width - 8
    //Layout.preferredHeight: parent.height - 8
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    color: "transparent"

    ColumnLayout {
        id: soundSettingsContent
        anchors.fill: parent

        Label {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 8
            Layout.bottomMargin: 0
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.fillHeight: false
            horizontalAlignment: Text.AlignLeft
            text: qsTr("Sound")
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
            id: soundScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            Layout.leftMargin: 12
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width - 12
                spacing: 12

                // Hauptschalter
                GroupBox {
                    Layout.fillWidth: true
                    title: qsTr("Klangeffekte")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        CustomToggle {
                            id: playSounds
                            label: qsTr("Klangeffekte aktivieren")
                            checked: SettingsManager ? SettingsManager.soundEnabled : false
                            onCheckedChanged: {
                                if (SettingsManager) SettingsManager.soundEnabled = checked
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            enabled: playSounds.checked

                            Label {
                                text: qsTr("Lautstärke:")
                                color: Config.StaticData.palette.secondary.col200
                                opacity: playSounds.checked ? 1.0 : 0.4
                            }

                            Slider {
                                id: soundVolumeSlider
                                Layout.fillWidth: true
                                from: 1
                                to: 10
                                stepSize: 1
                                value: SettingsManager ? SettingsManager.readConfigInt("SoundVolume") : 8
                                enabled: playSounds.checked
                                onMoved: {
                                    if (SettingsManager) SettingsManager.writeConfigInt("SoundVolume", Math.round(value))
                                }
                            }

                            Label {
                                text: Math.round(soundVolumeSlider.value)
                                color: Config.StaticData.palette.secondary.col200
                                opacity: playSounds.checked ? 1.0 : 0.4
                                Layout.minimumWidth: 20
                            }
                        }
                    }
                }

                // Klang-Kategorien
                GroupBox {
                    Layout.fillWidth: true
                    title: qsTr("Klang-Kategorien")
                    enabled: playSounds.checked

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4

                        CheckBox {
                            text: qsTr("Spielaktionen (Check, Call, Raise ...)")
                            checked: SettingsManager ? SettingsManager.readConfigInt("PlayGameActions") !== 0 : true
                            onCheckedChanged: {
                                if (SettingsManager) SettingsManager.writeConfigInt("PlayGameActions", checked ? 1 : 0)
                            }
                        }

                        CheckBox {
                            text: qsTr("Lobby-Chat-Benachrichtigungen")
                            checked: SettingsManager ? SettingsManager.readConfigInt("PlayLobbyChatNotification") !== 0 : true
                            onCheckedChanged: {
                                if (SettingsManager) SettingsManager.writeConfigInt("PlayLobbyChatNotification", checked ? 1 : 0)
                            }
                        }

                        CheckBox {
                            text: qsTr("Netzwerkspiel-Benachrichtigungen")
                            checked: SettingsManager ? SettingsManager.readConfigInt("PlayNetworkGameNotification") !== 0 : true
                            onCheckedChanged: {
                                if (SettingsManager) SettingsManager.writeConfigInt("PlayNetworkGameNotification", checked ? 1 : 0)
                            }
                        }

                        CheckBox {
                            text: qsTr("Blind-Erhöhungs-Benachrichtigung")
                            checked: SettingsManager ? SettingsManager.readConfigInt("PlayBlindRaiseNotification") !== 0 : true
                            onCheckedChanged: {
                                if (SettingsManager) SettingsManager.writeConfigInt("PlayBlindRaiseNotification", checked ? 1 : 0)
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
