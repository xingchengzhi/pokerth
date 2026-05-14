import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../config" as Config
import "../components"


Rectangle {
    id: serverConnectionPage
    width: mainWindow.width
    height: mainWindow.height
    color: "transparent"

    Image {
        id: serverConnectionBackground
        anchors.fill: parent
        source: "../resources/startWindowBackground.png"
        fillMode: Image.PreserveAspectCrop
    }

    Component.onCompleted: {
        // Load saved credentials from config
        usernameInput.text = ServerConnection.savedUsername
        passwordInput.text = ServerConnection.savedPassword
        rememberMeCheckbox.isChecked = ServerConnection.rememberPassword
    }

    // Connections to backend signals
    Connections {
        target: ServerConnection

        function onConnectionProgressChanged(progress) {
            connectionProgress.value = progress
        }

        function onStatusMessageChanged(message) {
            statusText.text = message
        }

        function onConnectionSucceeded() {
            console.log("Connection succeeded!")
        }

        function onConnectionFailed(errorMessage) {
            console.log("Connection failed:", errorMessage)
            statusText.text = errorMessage
            statusText.color = "#FF5252"

            Qt.callLater(function() {
                mainStack.currentIndex = 0
                statusText.color = Config.StaticData.palette.secondary.col300
            })
        }

        function onShowLobby() {
            console.log("Showing lobby...")
            mainStackView.push("LobbyPage.qml")
        }
    }

    ColumnLayout {
        anchors.fill: parent

        // Card – wie auf der StartPage
        Rectangle {
            id: loginCard
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(parent.width * 0.9, 360)
            Layout.preferredHeight: Math.min(parent.height * 0.88, 500)
            Layout.minimumHeight: 320
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Config.StaticData.palette.secondary.col700
                opacity: 0.92
                radius: 5
            }

            StackLayout {
                id: mainStack
                anchors.fill: parent
                anchors.margins: 28
                currentIndex: 0

                // View 0: Auswahl
                ColumnLayout {
                    id: initialChoicesView
                    spacing: 18

                    Item { Layout.fillHeight: true }

                    CustomButton {
                        text: qsTr("Login as User")
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: mainStack.currentIndex = 1
                    }

                    CustomButton {
                        text: qsTr("Register")
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: Qt.openUrlExternally("https://www.pokerth.net/ucp.php?mode=register")
                    }

                    CustomButton {
                        text: qsTr("Continue as Guest")
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: {
                            var guestName = "Guest" + Math.floor(Math.random() * 10000)
                            usernameLabel.text = guestName
                            connectionProgress.value = 0
                            mainStack.currentIndex = 2
                            ServerConnection.connectToServer(guestName, "", true, false)
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // View 1: Login-Formular
                ColumnLayout {
                    id: loginFormView
                    spacing: 12

                    Item { Layout.fillHeight: true }

                    Label {
                        text: qsTr("User Login")
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Config.StaticData.loadedFont.font.family
                        font.bold: true
                        font.pixelSize: Config.Theme.fontSizeTitle
                        color: Config.StaticData.palette.secondary.col200
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Config.StaticData.palette.secondary.col500
                    }

                    TextField {
                        id: usernameInput
                        placeholderText: qsTr("Username")
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.Theme.touchTarget
                        font.family: Config.StaticData.loadedFont.font.family
                        color: Config.StaticData.palette.secondary.col200
                        placeholderTextColor: Config.StaticData.palette.secondary.col400
                        background: Rectangle {
                            color: Config.StaticData.palette.secondary.col600
                            border.color: Config.StaticData.palette.secondary.col500
                            border.width: 1
                            radius: 3
                        }
                    }

                    TextField {
                        id: passwordInput
                        placeholderText: qsTr("Password")
                        echoMode: TextInput.Password
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.Theme.touchTarget
                        font.family: Config.StaticData.loadedFont.font.family
                        color: Config.StaticData.palette.secondary.col200
                        placeholderTextColor: Config.StaticData.palette.secondary.col400
                        background: Rectangle {
                            color: Config.StaticData.palette.secondary.col600
                            border.color: Config.StaticData.palette.secondary.col500
                            border.width: 1
                            radius: 3
                        }
                    }

                    CustomCheckBox {
                        id: rememberMeCheckbox
                        objectName: "loginRememberMe"
                        label: qsTr("Remember me")
                        defaultValue: false
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Config.Theme.spacing

                        CustomButton {
                            text: qsTr("Back")
                            Layout.fillWidth: true
                            onClicked: mainStack.currentIndex = 0
                        }

                        CustomButton {
                            text: qsTr("Login")
                            Layout.fillWidth: true
                            onClicked: {
                                console.log("Login clicked. Username:", usernameInput.text, "Remember me:", rememberMeCheckbox.isChecked)
                                usernameLabel.text = usernameInput.text
                                connectionProgress.value = 0
                                mainStack.currentIndex = 2
                                ServerConnection.connectToServer(usernameInput.text, passwordInput.text, false, rememberMeCheckbox.isChecked)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // View 2: Verbindungsaufbau
                ColumnLayout {
                    id: guestLoginView
                    spacing: 20

                    Item { Layout.fillHeight: true }

                    Text {
                        text: qsTr("Connecting as...")
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: Config.Theme.fontSizeBody
                        color: Config.StaticData.palette.secondary.col300
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        id: usernameLabel
                        text: qsTr("Username/Guest")
                        font.family: Config.StaticData.loadedFont.font.family
                        font.pixelSize: Config.Theme.fontSizeTitle
                        font.bold: true
                        color: Config.StaticData.palette.secondary.col200
                        Layout.alignment: Qt.AlignHCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ProgressBar {
                            id: connectionProgress
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            from: 0
                            to: 100
                            value: 0

                            background: Rectangle {
                                implicitWidth: 200
                                implicitHeight: 8
                                color: Config.StaticData.palette.secondary.col600
                                border.color: Config.StaticData.palette.secondary.col500
                                border.width: 1
                                radius: 4
                            }

                            contentItem: Item {
                                implicitWidth: 200
                                implicitHeight: 6

                                Rectangle {
                                    width: connectionProgress.visualPosition * parent.width
                                    height: parent.height
                                    radius: 4
                                    color: Config.StaticData.palette.secondary.col300
                                }
                            }
                        }

                        Text {
                            id: statusText
                            text: qsTr("Initializing connection...")
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pixelSize: Config.Theme.fontSizeBody
                            color: Config.StaticData.palette.secondary.col300
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    Item { Layout.fillHeight: true }

                    CustomButton {
                        text: qsTr("Cancel")
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: {
                            ServerConnection.cancelConnection()
                            connectionProgress.value = 0
                            mainStack.currentIndex = 0
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}