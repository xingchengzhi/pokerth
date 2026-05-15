import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

import "../config" as Config
import QtQuick.Dialogs

Rectangle {
    id: nicknameAvatarSettings
    //Layout.preferredWidth: parent.width - 8
    //Layout.preferredHeight: parent.height - 8
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    color: "transparent"

    property var activeAvatarField: null
    property string activeAvatarKey: ""

    FileDialog {
        id: avatarFileDialog
        nameFilters: [qsTr("Bilder") + " (*.png *.jpg *.jpeg *.gif *.bmp)"]
        onAccepted: {
            let path = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""))
            if (nicknameAvatarSettings.activeAvatarField)
                nicknameAvatarSettings.activeAvatarField.text = path
            if (SettingsManager && nicknameAvatarSettings.activeAvatarKey)
                SettingsManager.writeConfigString(nicknameAvatarSettings.activeAvatarKey, path)
        }
    }

    ColumnLayout {
        id: nicknameAvatarSettingsContent
        anchors.fill: parent

        Label {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            horizontalAlignment: Text.AlignLeft
            text: qsTr("Nicknamen/Avatare")
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
            id: nickScrollView
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

                // Mein Name / Avatar
                GroupBox {
                    Layout.fillWidth: true
                    title: qsTr("Mein Spieler")

                    ColumnLayout {
                        anchors.fill: parent

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.preferredWidth: 120
                                text: qsTr("Mein Nickname:")
                                color: Config.StaticData.palette.secondary.col200
                            }

                            TextField {
                                id: myNicknameField
                                Layout.fillWidth: true
                                text: SettingsManager ? SettingsManager.readConfigString("MyName") : ""
                                onEditingFinished: {
                                    if (SettingsManager) SettingsManager.writeConfigString("MyName", text.trim())
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 56
                                Layout.alignment: Qt.AlignVCenter
                                radius: 6
                                color: Config.StaticData.palette.secondary.col600
                                clip: true

                                Image {
                                    id: myAvatarPreview
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: myAvatarField.text.startsWith("/")
                                            ? ("file://" + myAvatarField.text.replace(/#/g, "%23"))
                                            : ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    visible: status === Image.Ready
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: qsTr("Mein Avatar:")
                                    color: Config.StaticData.palette.secondary.col200
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: myAvatarField.text.length > 0
                                          ? myAvatarField.text.split("/").pop()
                                          : qsTr("Kein Avatar gewählt")
                                    font.pointSize: 10
                                    font.family: Config.StaticData.loadedFont.font.family
                                    color: Config.StaticData.palette.secondary.col400
                                    elide: Text.ElideLeft
                                }
                            }

                            TextField {
                                id: myAvatarField
                                visible: false
                                text: SettingsManager ? SettingsManager.readConfigString("MyAvatar") : ""
                            }

                            Button {
                                text: qsTr("Auswählen...")
                                onClicked: {
                                    nicknameAvatarSettings.activeAvatarField = myAvatarField
                                    nicknameAvatarSettings.activeAvatarKey = "MyAvatar"
                                    avatarFileDialog.open()
                                }
                            }
                        }
                    }
                }

                // Gegner 1-9 Namen und Avatare
                Repeater {
                    model: 9
                    delegate: GroupBox {
                        Layout.fillWidth: true
                        title: qsTr("Gegner %1").arg(index + 1)

                        ColumnLayout {
                            anchors.fill: parent

                            RowLayout {
                                Layout.fillWidth: true

                                Label {
                                    Layout.preferredWidth: 120
                                    text: qsTr("Nickname:")
                                    color: Config.StaticData.palette.secondary.col200
                                }

                                TextField {
                                    id: opponentNameField
                                    Layout.fillWidth: true
                                    text: SettingsManager ? SettingsManager.readConfigString("Opponent" + (index + 1) + "Name") : ""
                                    onEditingFinished: {
                                        if (SettingsManager) SettingsManager.writeConfigString("Opponent" + (index + 1) + "Name", text.trim())
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.preferredHeight: 56
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 6
                                    color: Config.StaticData.palette.secondary.col600
                                    clip: true

                                    Image {
                                        id: opponentAvatarPreview
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: opponentAvatarField.text.startsWith("/")
                                                ? ("file://" + opponentAvatarField.text.replace(/#/g, "%23"))
                                                : ""
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                        visible: status === Image.Ready
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: qsTr("Avatar:")
                                        color: Config.StaticData.palette.secondary.col200
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: opponentAvatarField.text.length > 0
                                              ? opponentAvatarField.text.split("/").pop()
                                              : qsTr("Kein Avatar gewählt")
                                        font.pointSize: 10
                                        font.family: Config.StaticData.loadedFont.font.family
                                        color: Config.StaticData.palette.secondary.col400
                                        elide: Text.ElideLeft
                                    }
                                }

                                TextField {
                                    id: opponentAvatarField
                                    visible: false
                                    text: SettingsManager ? SettingsManager.readConfigString("Opponent" + (index + 1) + "Avatar") : ""
                                }

                                Button {
                                    text: qsTr("Auswählen...")
                                    onClicked: {
                                        nicknameAvatarSettings.activeAvatarField = opponentAvatarField
                                        nicknameAvatarSettings.activeAvatarKey = "Opponent" + (index + 1) + "Avatar"
                                        avatarFileDialog.open()
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
