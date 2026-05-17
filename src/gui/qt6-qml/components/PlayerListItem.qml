import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage

import "../config" as Config

ItemDelegate {
    id: playerItem

    required property int index
    required property int collapseResetCounter
    required property var listView

    readonly property int playerListRevision: Lobby ? Lobby.playerListRevision : 0
    readonly property var playerEntry: {
        var _revision = playerListRevision
        return Lobby ? Lobby.playerListEntry(index) : ({})
    }
    readonly property int targetPlayerId: playerEntry.playerId || 0
    readonly property string displayName: playerEntry.playerName || ""
    readonly property bool adminPlayer: !!playerEntry.isAdmin
    readonly property bool guestPlayer: !!playerEntry.isGuest
    readonly property string playerCountryCode: playerEntry.countryCode || ""

    width: listView.width
    height: visible ? ((expanded && hasActions) ? expandedHeight : rowHeight) : 0

    property bool expanded: false
    property bool playerIgnored: false
    readonly property int rowHeight: 30
    readonly property int actionButtonHeight: 24
    readonly property int actionSpacing: 3
    readonly property int actionCount: (canInvite ? 1 : 0)
                                     + (canIgnore ? 1 : 0)
                                     + (canUnignore ? 1 : 0)
                                     + (canShowPlayerStats ? 1 : 0)
                                     + (canAdminModerate ? 1 : 0)
    readonly property int expandedHeight: rowHeight + 5
                                        + (actionCount * actionButtonHeight)
                                        + (Math.max(0, actionCount - 1) * actionSpacing)

    readonly property bool hasSettingsManager: typeof SettingsManager !== "undefined" && !!SettingsManager
    readonly property bool isSelf: Lobby && targetPlayerId === Lobby.myPlayerId
    readonly property bool canInvite: Lobby && Lobby.canInviteFromCurrentGame && !isSelf && !guestPlayer
    readonly property bool canAdminModerate: Lobby && Lobby.isCurrentPlayerAdmin && !isSelf
    readonly property bool canShowPlayerStats: !guestPlayer
    readonly property bool canIgnore: !isSelf && !guestPlayer && !playerIgnored
    readonly property bool canUnignore: !isSelf && !guestPlayer && playerIgnored
    readonly property bool hasActions: canInvite || canAdminModerate || canIgnore || canUnignore || canShowPlayerStats

    readonly property color inviteColor: Config.StaticData.chartColor(0, true)
    readonly property color ignoreColor: Config.StaticData.chartColor(8, true)
    readonly property color statsColor: Config.StaticData.chartColor(9, true)
    readonly property color banColor: Config.StaticData.chartColor(5, true)

    function refreshIgnoreState() {
        if (!hasSettingsManager) {
            playerIgnored = false
            return
        }
        var ignoreList = SettingsManager.readConfigStringList("PlayerIgnoreList")
        playerIgnored = ignoreList.indexOf(displayName) !== -1
    }

    function addToIgnoreList() {
        if (!hasSettingsManager) {
            return
        }
        var ignoreList = SettingsManager.readConfigStringList("PlayerIgnoreList")
        if (ignoreList.indexOf(displayName) === -1) {
            ignoreList.push(displayName)
            SettingsManager.writeConfigStringList("PlayerIgnoreList", ignoreList)
        }
        refreshIgnoreState()
    }

    function removeFromIgnoreList() {
        if (!hasSettingsManager) {
            return
        }
        var ignoreList = SettingsManager.readConfigStringList("PlayerIgnoreList")
        var idx = ignoreList.indexOf(displayName)
        if (idx !== -1) {
            ignoreList.splice(idx, 1)
            SettingsManager.writeConfigStringList("PlayerIgnoreList", ignoreList)
        }
        refreshIgnoreState()
    }

    Component.onCompleted: refreshIgnoreState()
    onDisplayNameChanged: refreshIgnoreState()
    onCollapseResetCounterChanged: expanded = false
    
    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    
    contentItem: ColumnLayout {
        spacing: 0
        
        // Header row: flag + name + right-aligned expander
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            Layout.topMargin: 0
            Layout.bottomMargin: 0
            spacing: 5

            // Flag
            Image {
                visible: playerCountryCode !== ""
                source: playerCountryCode !== ""
                    ? "qrc:/resources/cflags/" + playerCountryCode.toLowerCase() + ".svg"
                        : ""
                Layout.preferredWidth: 18
                Layout.preferredHeight: 14
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
            
            // Player name
            Text {
                text: displayName
                font.family: Config.StaticData.loadedFont.font.family
                font.pixelSize: listView.height > 100 ? 12 : 11
                color: adminPlayer ? Config.StaticData.chartColor(3, true) : Config.StaticData.palette.secondary.col200
                font.bold: adminPlayer
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
            }

            // Expander caret
            VectorImage {
                source: "qrc:/resources/caretLeft.svg"
                rotation: expanded ? -180 : -90
                Behavior on rotation { NumberAnimation { duration: 150 } }
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                fillMode: VectorImage.PreserveAspectFit
                opacity: 0.6
                visible: hasActions

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (playerItem.hasActions) {
                            playerItem.expanded = !playerItem.expanded
                        }
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
        
        // Action buttons (expanded)
        ColumnLayout {
            visible: expanded && hasActions
            Layout.fillWidth: true
            Layout.topMargin: 5
            spacing: 3
            
            // Invite to game
            Button {
                text: qsTr("Invite to Game")
                visible: canInvite
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                font.pixelSize: 10
                
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
                
                background: Rectangle {
                    color: parent.pressed ? Qt.darker(playerItem.inviteColor, 1.35)
                           : parent.hovered ? playerItem.inviteColor
                           : Qt.darker(playerItem.inviteColor, 1.18)
                    radius: 3
                    border.width: 1
                    border.color: Qt.darker(playerItem.inviteColor, 1.55)
                }
                
                contentItem: Text {
                    text: parent.text
                    color: Config.StaticData.palette.secondary.col100
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: parent.font.pixelSize
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    if (Lobby) Lobby.invitePlayer(targetPlayerId)
                    playerItem.expanded = false
                }
            }

            // Ignore player
            Button {
                text: qsTr("Ignore player")
                visible: canIgnore
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                font.pixelSize: 10

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                background: Rectangle {
                      color: parent.pressed ? Qt.darker(playerItem.ignoreColor, 1.35)
                          : parent.hovered ? playerItem.ignoreColor
                          : Qt.darker(playerItem.ignoreColor, 1.18)
                    radius: 3
                    border.width: 1
                      border.color: Qt.darker(playerItem.ignoreColor, 1.55)
                }

                contentItem: Text {
                    text: parent.text
                    color: Config.StaticData.palette.secondary.col100
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: parent.font.pixelSize
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    playerItem.addToIgnoreList()
                    playerItem.expanded = false
                }
            }

            // Unignore player
            Button {
                text: qsTr("Unignore player")
                visible: canUnignore
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                font.pixelSize: 10

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                background: Rectangle {
                      color: parent.pressed ? Qt.darker(playerItem.ignoreColor, 1.35)
                          : parent.hovered ? playerItem.ignoreColor
                          : Qt.darker(playerItem.ignoreColor, 1.18)
                    radius: 3
                    border.width: 1
                      border.color: Qt.darker(playerItem.ignoreColor, 1.55)
                }

                contentItem: Text {
                    text: parent.text
                    color: Config.StaticData.palette.secondary.col100
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: parent.font.pixelSize
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    playerItem.removeFromIgnoreList()
                    playerItem.expanded = false
                }
            }

            // Show player stats (widget parity)
            Button {
                text: qsTr("Show player stats")
                visible: canShowPlayerStats
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                font.pixelSize: 10

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                background: Rectangle {
                      color: parent.pressed ? Qt.darker(playerItem.statsColor, 1.35)
                          : parent.hovered ? playerItem.statsColor
                          : Qt.darker(playerItem.statsColor, 1.18)
                    radius: 3
                    border.width: 1
                      border.color: Qt.darker(playerItem.statsColor, 1.55)
                }

                contentItem: Text {
                    text: parent.text
                    color: Config.StaticData.palette.secondary.col100
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: parent.font.pixelSize
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    var url = "https://www.pokerth.net/redirect_user_profile.php?nick=" + encodeURIComponent(displayName)
                    var opened = false
                    if (Lobby) {
                        opened = Lobby.openExternalUrl(url)
                    } else {
                        opened = Qt.openUrlExternally(url)
                    }

                    if (opened) {
                        playerItem.expanded = false
                    } else {
                        console.warn("Failed to open player stats URL:", url)
                    }
                }
            }
            
            // Admin action (widget parity)
            Button {
                text: qsTr("Total kickban")
                visible: canAdminModerate
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                font.pixelSize: 10
                
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
                
                background: Rectangle {
                    color: parent.pressed ? Qt.darker(playerItem.banColor, 1.35)
                           : parent.hovered ? playerItem.banColor
                           : Qt.darker(playerItem.banColor, 1.18)
                    radius: 3
                    border.width: 1
                    border.color: Qt.darker(playerItem.banColor, 1.55)
                }
                
                contentItem: Text {
                    text: parent.text
                    color: Config.StaticData.palette.secondary.col100
                    font.family: Config.StaticData.loadedFont.font.family
                    font.pixelSize: parent.font.pixelSize
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    if (Lobby) Lobby.adminBanPlayer(targetPlayerId)
                    playerItem.expanded = false
                }
            }
        }
    }
    
    background: Rectangle {
        color: playerItem.hovered
               ? Qt.lighter(Config.StaticData.palette.secondary.col700, 1.2)
               : "transparent"
        radius: 3
    }
}
