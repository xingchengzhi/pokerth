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

    // Set by ApplicationWindow and GuiSettings — same semantics as StaticData.darkMode
    // 0 = Hell (Light), 1 = Dunkel (Dark), 2 = Automatisch
    property int darkMode: 1

    readonly property bool isDark: darkMode !== 0  // 0=Hell → false, alles andere (1=Dunkel, 2=Auto) → true

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
    readonly property color colorBackground:    isDark ? "#1d222b" : "#f0f3f8"   // col700
    readonly property color colorSurface:       isDark ? "#394150" : "#dce2ec"   // col600
    readonly property color colorSurfaceMid:    isDark ? "#576378" : "#a0acc4"   // col500
    readonly property color colorSurfaceLight:  isDark ? "#7787a3" : "#7787a3"   // col400

    // Text / icon levels
    readonly property color colorTextPrimary:   isDark ? "#eff1f5" : "#1d222b"   // col100
    readonly property color colorTextSecondary: isDark ? "#cdd3e0" : "#394150"   // col200
    readonly property color colorTextMuted:     isDark ? "#a0acc4" : "#576378"   // col300

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
