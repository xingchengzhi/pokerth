import QtQuick
import QtQuick.Controls

import "../config" as Config

// PokerTH base button — built on AbstractButton for keyboard + accessibility support.
// Touch target is at least Theme.touchTarget (48dp on mobile, 44dp on desktop).
AbstractButton {
    id: customButton

    implicitWidth:  Config.Theme.buttonWidth < 0 ? parent.width : Config.Theme.buttonWidth
    implicitHeight: Config.Theme.touchTarget

    // Visual feedback state
    background: Rectangle {
        radius: Config.Theme.radiusSmall
        color: customButton.pressed
               ? Config.Theme.colorSurface
               : customButton.hovered
                 ? Config.StaticData.palette.secondary.col600
                 : Config.StaticData.palette.secondary.col700
        border.color: customButton.hovered || customButton.pressed
                      ? Config.Theme.colorTextPrimary
                      : Config.Theme.colorTextSecondary
        border.width: 1

        Behavior on color { ColorAnimation { duration: 100 } }
    }

    contentItem: Text {
        text: customButton.text
        color: customButton.hovered || customButton.pressed
               ? Config.Theme.colorTextPrimary
               : Config.Theme.colorTextSecondary
        font.family: Config.StaticData.loadedFont.font.family
        font.pixelSize: Config.Theme.fontSizeBody
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment:   Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: 100 } }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}

