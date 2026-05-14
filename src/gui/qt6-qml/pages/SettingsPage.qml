import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects

import "../config" as Config
import "../components"

Rectangle {
    id: settingsPage

    Layout.fillWidth: true
    Layout.fillHeight: true
    color: Config.StaticData.palette.secondary.col700

    // Aktuelle Kategorie für den Compact-Strip
    property int currentCategoryIndex: 0

    // Compact: horizontale Icon-Tabs für Kategorien
    Rectangle {
        id: compactCategoryStrip
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Config.Theme.touchTarget
        visible: Config.Responsive.compact
        color: Config.StaticData.palette.secondary.col700
        z: 1

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: settingsMenuListItems
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors { fill: parent; margins: 3 }
                        radius: Config.Theme.radiusSmall
                        color: settingsPage.currentCategoryIndex === index
                               ? Config.StaticData.palette.secondary.col600
                               : "transparent"

                        VectorImage {
                            anchors.centerIn: parent
                            width: Config.Theme.iconSize
                            height: Config.Theme.iconSize
                            source: "../resources/" + icon + ".svg"
                        }
                    }

                    TapHandler {
                        onTapped: {
                            settingsPage.currentCategoryIndex = index
                            settingsStackView.replaceCurrentItem(
                                "qrc:/components/" + source + "Settings.qml",
                                {}, StackView.Immediate)
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Config.StaticData.palette.secondary.col500
        }
    }

    RowLayout {
        anchors {
            top: Config.Responsive.compact ? compactCategoryStrip.bottom : parent.top
            left: parent.left; right: parent.right; bottom: parent.bottom
        }
        spacing: 0

        Rectangle {
            id: settingsNMenuBox
            visible: !Config.Responsive.compact
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: mainWindow.width / 6
            Layout.minimumWidth: 250
            Layout.preferredHeight: mainWindow.height
            Layout.topMargin: 4
            Layout.leftMargin: 16
            Layout.rightMargin: 8
            Layout.bottomMargin: 16
            border.width: 1
            border.color: Config.StaticData.palette.secondary.col500
            radius: 5
            color: "transparent"

            ListView {
                id: settingsMenuList
                model: settingsMenuListItems
                width: parent.width
                height: parent.height - 16
                anchors.centerIn: parent
                currentIndex: 0

                property int prevIndex: 0

                delegate: Rectangle {
                    id: settingsMenuListItem

                    property alias labelText: label.text
                    property alias labelColor: label.color
                    property alias iconSource: iconImage.source
                    property alias iconWidth: iconImage.width
                    property alias iconHeight: iconImage.height
                    property alias iconColor: iconImageCol.colorizationColor
                    signal clicked

                    labelText: name
                    iconSource: "../resources/" + icon + ".svg"

                    color: ListView.isCurrentItem ? Config.StaticData.palette.secondary.col600 : "transparent"
                    labelColor: ListView.isCurrentItem ? Config.StaticData.palette.secondary.col100 : Config.StaticData.palette.secondary.col200
                    width: parent.width
                    height: 36

                    RowLayout {
                        anchors.fill: parent
                        spacing: 6

                        VectorImage {
                            id: iconImage
                            Layout.leftMargin: 16
                            Layout.topMargin: 4
                            Layout.bottomMargin: 4
                            Layout.alignment: Qt.AlignLeft
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: 24

                            MultiEffect {
                                id: iconImageCol
                                source: iconImage
                                anchors.fill: iconImage
                                colorization: 1.0 // opacity equivalent
                                colorizationColor: Config.StaticData.palette.secondary.col200
                            }
                        }

                        Text {
                            id: label
                            Layout.alignment: Qt.AlignLeft
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            Layout.bottomMargin: 4
                            font.family: Config.StaticData.loadedFont.font.family
                            font.pointSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            settingsMenuList.currentIndex = index;
                            settingsStackView.replaceCurrentItem("qrc:/components/" + source + "Settings.qml", {}, StackView.Immediate);
                        }

                        onEntered: {
                            iconImageCol.colorizationColor = label.color = Config.StaticData.palette.secondary.col100;
                            settingsMenuListItem.color = Config.StaticData.palette.secondary.col600;
                        }

                        onExited: {
                            iconImageCol.colorizationColor = label.color = Config.StaticData.palette.secondary.col200;
                            if (settingsMenuList.currentIndex !== index) {
                                iconImageCol.colorizationColor = label.color = Config.StaticData.palette.secondary.col200;
                                settingsMenuListItem.color = "transparent";
                            }
                        }
                    }
                }

                onCurrentIndexChanged: {
                    settingsMenuList.currentItem.labelColor = settingsMenuList.currentItem.iconColor = Config.StaticData.palette.secondary.col100;
                    settingsMenuList.currentItem.color = Config.StaticData.palette.secondary.col600;
                    settingsMenuList.itemAtIndex(settingsMenuList.prevIndex).labelColor = settingsMenuList.itemAtIndex(settingsMenuList.prevIndex).iconColor = Config.StaticData.palette.secondary.col200;
                    settingsMenuList.itemAtIndex(settingsMenuList.prevIndex).color = "transparent";
                    prevIndex = settingsMenuList.currentIndex;
                }
            }
        }

        Rectangle {
            id: settingsContentBox
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.horizontalStretchFactor: 2
            Layout.preferredHeight: mainWindow.height
            Layout.topMargin: 4
            Layout.leftMargin: Config.Responsive.compact ? 0 : 8
            Layout.rightMargin: Config.Responsive.compact ? 0 : 16
            Layout.bottomMargin: Config.Responsive.compact ? 0 : 16
            border.width: Config.Responsive.compact ? 0 : 1
            border.color: Config.StaticData.palette.secondary.col500
            radius: 5
            color: "transparent"

            StackView {
                id: settingsStackView
                anchors.fill: parent
                initialItem: GuiSettings {}
            }
        }
    }

    ListModel {
        id: settingsMenuListItems
        ListElement {
            name: qsTr("Benutzeroberfläche")
            icon: "monitor"
            source: "Gui"
        }
        ListElement {
            name: qsTr("Stil")
            icon: "palette"
            source: "Style"
        }
        ListElement {
            name: qsTr("Sound")
            icon: "speaker"
            source: "Sound"
        }
        ListElement {
            name: qsTr("Lokales Spiel")
            icon: "spade"
            source: "LocalGame"
        }
        ListElement {
            name: qsTr("Netzwerkspiel")
            icon: "network"
            source: "NetworkGame"
        }
        ListElement {
            name: qsTr("Internetspiel")
            icon: "globe"
            source: "InternetGame"
        }
        ListElement {
            name: qsTr("Nicknamen/Avatare")
            icon: "userSquare"
            source: "NicknameAvatar"
        }
        ListElement {
            name: qsTr("Log-Nachrichten")
            icon: "terminalWindow"
            source: "Logs"
        }
        ListElement {
            name: qsTr("Standardeinstellung")
            icon: "arrowUpLeft"
            source: "Reset"
        }
    }
}
