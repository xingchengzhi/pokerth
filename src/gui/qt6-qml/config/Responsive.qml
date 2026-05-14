pragma Singleton
import QtQuick

// Responsive singleton: bind width/height from ApplicationWindow.
// Usage in pokerth.qml:
//   onWidthChanged:  Config.Responsive.windowWidth  = width
//   onHeightChanged: Config.Responsive.windowHeight = height
QtObject {
    id: root

    // Set by ApplicationWindow
    property real windowWidth:  900
    property real windowHeight: 600

    // Orientation
    readonly property bool portrait:  windowHeight > windowWidth
    readonly property bool landscape: windowWidth >= windowHeight

    // Breakpoints  (logical pixels / dp)
    // phonePortrait  < 600 wide
    // phoneLandscape >= 600 and < 900 wide
    // tablet         >= 900 and < 1400 wide
    // desktop        >= 1400 wide
    readonly property bool phonePortrait:  portrait  && windowWidth  < 600
    readonly property bool phoneLandscape: landscape && windowHeight < 600
    readonly property bool compact:        windowWidth < 600
    readonly property bool tablet:         windowWidth >= 900  && windowWidth < 1400
    readonly property bool desktop:        windowWidth >= 1400

    // Convenience: number of columns for a simple grid
    readonly property int columns: compact ? 1 : tablet ? 2 : 3
}
