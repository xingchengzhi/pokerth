pragma Singleton
import QtQuick

// Adaptive design tokens — all values react to window dimensions.
// NOTE: We cannot `import Config` here (same-module circular dependency in Qt 6).
// windowWidth / windowHeight must be kept in sync by ApplicationWindow
// alongside Config.Responsive (see pokerth.qml onWidthChanged / onHeightChanged).
QtObject {

    // Set by ApplicationWindow — mirrors Responsive.windowWidth/windowHeight
    property real windowWidth:  900
    property real windowHeight: 600

    readonly property bool compact: windowWidth < 600
    readonly property bool tablet:  windowWidth >= 900 && windowWidth < 1400

    // ── Spacing & Layout ────────────────────────────────────────────────────
    readonly property real margin:  compact ? 12 : tablet ? 20 : 28
    readonly property real spacing: compact ?  8 : tablet ? 12 : 16

    // ── Touch Targets ────────────────────────────────────────────────────────
    // Apple HIG / Material: minimum interactive area 44–48 dp
    readonly property real touchTarget:   compact ? 48 : 44
    readonly property real buttonHeight:  compact ? 48 : 40
    readonly property real buttonWidth:   compact ? -1 : 180   // -1 = fillWidth
    readonly property real iconSize:      compact ? 28 : 24
    readonly property real smallIconSize: compact ? 22 : 18

    // ── Border Radius ────────────────────────────────────────────────────────
    readonly property real radiusSmall:  4
    readonly property real radiusMedium: 8
    readonly property real radiusLarge:  16

    // ── Typography ───────────────────────────────────────────────────────────
    readonly property real fontSizeCaption: compact ? 11 : 12
    readonly property real fontSizeBody:    compact ? 14 : 15
    readonly property real fontSizeLabel:   compact ? 14 : 14
    readonly property real fontSizeTitle:   compact ? 20 : 24
    readonly property real fontSizeHeader:  compact ? 26 : 32

    // ── Colors (mirrors StaticData.palette for use without Config prefix) ────
    // Background levels
    readonly property color colorBackground:    "#1d222b"   // col700
    readonly property color colorSurface:       "#394150"   // col600
    readonly property color colorSurfaceMid:    "#576378"   // col500
    readonly property color colorSurfaceLight:  "#7787a3"   // col400

    // Text / icon levels
    readonly property color colorTextPrimary:   "#eff1f5"   // col100
    readonly property color colorTextSecondary: "#cdd3e0"   // col200
    readonly property color colorTextMuted:     "#a0acc4"   // col300

    // Accent (poker gold — used for active player, chips, highlights)
    readonly property color colorAccent:        "#E3C800"
    readonly property color colorAccentDim:     "#b09a00"

    // Semantic
    readonly property color colorDanger:        "#e05050"
    readonly property color colorSuccess:       "#50c878"

    // ── Opacity helpers ──────────────────────────────────────────────────────
    readonly property real overlayOpacity: 0.80
    readonly property real dimmedOpacity:  0.40
}
