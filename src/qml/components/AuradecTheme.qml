pragma Singleton
import QtQuick

QtObject {
    // Backgrounds
    readonly property color bgPrimary:   "#060507"
    readonly property color bgSecondary: "#0E0B13"
    readonly property color bgTertiary:  "#15121C"
    readonly property color bgCard:      "#110E18"
    readonly property color bgOverlay:   Qt.rgba(6/255, 5/255, 7/255, 0.88)

    // Brand
    readonly property color brand:       "#FF5C1A"
    readonly property color brandHover:  "#FF7A40"
    readonly property color brandDim:    Qt.rgba(255/255, 92/255, 26/255, 0.15)
    readonly property color gold:        "#F5B32A"
    readonly property color green:       "#29F89E"
    readonly property color coral:       "#FF4D6A"

    // Text
    readonly property color textPrimary:   "#ECE5D8"
    readonly property color textSecondary: Qt.rgba(236/255, 229/255, 216/255, 0.55)
    readonly property color textMuted:     Qt.rgba(236/255, 229/255, 216/255, 0.30)

    // Surfaces
    readonly property color surfaceHover:  Qt.rgba(255/255, 255/255, 255/255, 0.05)
    readonly property color surfaceBorder: Qt.rgba(255/255, 255/255, 255/255, 0.08)
    readonly property color surfaceActive: Qt.rgba(255/255, 92/255, 26/255, 0.12)

    // Fonts
    readonly property string fontDisplay: "Syne"
    readonly property string fontBody:    "Barlow"
    readonly property string fontMono:    "JetBrains Mono"

    // Radii
    readonly property int radiusSm:   8
    readonly property int radiusMd:   12
    readonly property int radiusLg:   20
    readonly property int radiusXl:   32
    readonly property int radiusPill: 999

    // Spacing
    readonly property int spaceXs:  4
    readonly property int spaceSm:  8
    readonly property int spaceMd:  16
    readonly property int spaceLg:  24
    readonly property int spaceXl:  32

    // Sidebar
    readonly property int sidebarWidth: 272
    readonly property int playerBarHeight: 112
}
