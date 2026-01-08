import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../config" as Config


Rectangle {
    id: serverConnectionPage
    width: mainWindow.width
    height: mainWindow.height
    color: Config.StaticData.palette.secondary.col700

    StackLayout {
        id: mainStack
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.9, 500)
        height: Math.min(parent.height * 0.9, 400)
        currentIndex: 0 // Start with the initial choices view

        // View 0: Initial choices
        ColumnLayout {
            id: initialChoicesView
            spacing: 15
            Layout.fillHeight: true
            Layout.fillWidth: true

            Button {
                text: qsTr("Login as User")
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: 16
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                onClicked: {
                    mainStack.currentIndex = 1 // Switch to login form view
                    }
                }

                Button {
                    text: qsTr("Register")
                    Layout.alignment: Qt.AlignHCenter
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 16
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    onClicked: {
                        Qt.openUrlExternally("https://www.pokerth.net/ucp.php?mode=register")
                    }
                }

                Button {
                    text: qsTr("Continue as Guest")
                    Layout.alignment: Qt.AlignHCenter
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 16
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    onClicked: {
                        usernameLabel.text = "Guest" + Math.floor(Math.random() * 10000)
                        connectionProgress.value = 0
                        connectionTimer.start()
                        mainStack.currentIndex = 2 // Switch to connecting
                    }
                }
            }

            // View 1: Login as User form
            ColumnLayout {
                id: loginFormView
                spacing: 15
                Layout.fillHeight: true
                width: parent.width * 0.8

                Label {
                    text: qsTr("User Login")
                    Layout.alignment: Qt.AlignHCenter
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 20
                    color: Config.StaticData.palette.secondary.col200
                }

                TextField {
                    id: usernameInput
                    placeholderText: qsTr("Username")
                    Layout.fillWidth: true
                    font.family: Config.StaticData.loadedFont.font.family
                    color: Config.StaticData.palette.secondary.col200
                    background: Rectangle {
                        color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.5)
                        radius: 3
                    }
                    placeholderTextColor: Qt.lighter(Config.StaticData.palette.secondary.col200, 1.5)
                }

                TextField {
                    id: passwordInput
                    placeholderText: qsTr("Password")
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    font.family: Config.StaticData.loadedFont.font.family
                    color: Config.StaticData.palette.secondary.col200
                     background: Rectangle {
                        color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.5)
                        radius: 3
                    }
                    placeholderTextColor: Qt.lighter(Config.StaticData.palette.secondary.col200, 1.5)
                }

                CheckBox {
                    id: rememberMeCheckbox
                    text: qsTr("Remember me")
                    Layout.alignment: Qt.AlignLeft
                    font.family: Config.StaticData.loadedFont.font.family
                    contentItem: Text {
                        text: rememberMeCheckbox.text
                        font: rememberMeCheckbox.font
                        color: Config.StaticData.palette.secondary.col200
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: rememberMeCheckbox.indicator.width + rememberMeCheckbox.spacing
                    }
                }

                Button {
                    text: qsTr("Login")
                    Layout.alignment: Qt.AlignHCenter
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 16
                    onClicked: {
                        console.log("Login clicked. Username:", usernameInput.text, "Password:", passwordInput.text, "Remember me:", rememberMeCheckbox.checked)
                        usernameLabel.text = usernameInput.text
                        connectionProgress.value = 0
                        connectionTimer.start()
                        mainStack.currentIndex = 2 // Go to login section
                        // Login Logic
                    }
                }

                Button {
                    text: qsTr("Back")
                    Layout.alignment: Qt.AlignHCenter
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 14
                    onClicked: {
                        mainStack.currentIndex = 0 // Go back to initial choices
                    }
                }
            }

            // View 2: Connecting
            ColumnLayout {
                id: guestLoginView
                Layout.minimumWidth: 0
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 20

                Item {
                    Layout.fillHeight: true
                }

                Text {
                    text: qsTr("Connecting as...")
                    font.pixelSize: 14
                    Layout.fillWidth: false
                    font.family: Config.StaticData.loadedFont.font.family
                    color: Config.StaticData.palette.secondary.col200
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    id: usernameLabel
                    text: qsTr("Username/Guest")
                    font.pixelSize: 20
                    Layout.fillWidth: false
                    font.family: Config.StaticData.loadedFont.font.family
                    color: Config.StaticData.palette.secondary.col200
                    Layout.alignment: Qt.AlignHCenter
                }

                // Progress Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    ProgressBar {
                        id: connectionProgress
                        Layout.preferredWidth: Math.min(parent.width * 0.8, 300)
                        Layout.alignment: Qt.AlignHCenter
                        from: 0
                        to: 100
                        value: 0

                        background: Rectangle {
                            implicitWidth: 300
                            implicitHeight: 8
                            color: Qt.darker(Config.StaticData.palette.secondary.col700, 1.5)
                            radius: 4
                        }

                        contentItem: Item {
                            implicitWidth: 300
                            implicitHeight: 6

                            Rectangle {
                                width: connectionProgress.visualPosition * parent.width
                                height: parent.height
                                radius: 4
                                color: Config.StaticData.palette.secondary.col500
                            }
                        }
                    }

                    Text {
                        id: statusText
                        text: qsTr("Initializing connection...")
                        font.pixelSize: 14
                        font.family: Config.StaticData.loadedFont.font.family
                        color: Config.StaticData.palette.secondary.col300
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Button {
                    text: qsTr("Cancel")
                    Layout.alignment: Qt.AlignHCenter
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: 14
                    Layout.preferredWidth: 120
                    onClicked: {
                        connectionTimer.stop()
                        connectionProgress.value = 0
                        mainStack.currentIndex = 0 // Go back to initial choices
                    }
                }

                // Timer to simulate connection progress
                Timer {
                    id: connectionTimer
                    interval: 100
                    repeat: true
                    running: false
                    onTriggered: {
                        if (connectionProgress.value < 100) {
                            connectionProgress.value += Math.random() * 15
                            
                            // Update status text based on progress
                            if (connectionProgress.value < 30) {
                                statusText.text = qsTr("Connecting to server...")
                            } else if (connectionProgress.value < 60) {
                                statusText.text = qsTr("Authenticating...")
                            } else if (connectionProgress.value < 90) {
                                statusText.text = qsTr("Loading lobby data...")
                            } else {
                                statusText.text = qsTr("Connection successful!")
                            }
                        } else {
                            connectionTimer.stop()
                            // Navigate to lobby after a short delay
                            Qt.callLater(function() {
                                mainStackView.push("LobbyPage.qml")
                            })
                        }
                    }
                }
            }
        }
}