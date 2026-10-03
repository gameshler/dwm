pragma Singleton

import QtQuick
import Quickshell

/* The single source of every colour and dimension in the bar. The design rule
 * behind every value: nothing draws a box at rest. The background is the same
 * #000000 as the wallpaper, so fills and borders exist only for hover and
 * selection. Accents are Nord frost, shared with config.h and the rofi theme. */
Singleton {
    id: root

    readonly property string transparent: "#00000000"

    readonly property string bg: "#000000"
    readonly property string barBackground: "#000000"

    readonly property string surface: "#101014"
    readonly property string surfaceHover: "#17171D"
    readonly property string surfaceActive: "#1E1E26"

    readonly property string border: "#1A1A20"
    readonly property string borderStrong: "#2E2E3A"

    readonly property string text: "#70707C"
    readonly property string textStrong: "#E8E8EC"
    readonly property string textMuted: "#3E3E48"

    readonly property string accent: "#88C0D0"
    readonly property string accentSecondary: "#5E81AC"
    readonly property string danger: "#BF616A"
    readonly property string warning: "#EBCB8B"
    readonly property string success: "#A3BE8C"

    readonly property string controlNormalFill: transparent
    readonly property string controlNormalBorder: transparent
    readonly property string controlNormalText: text
    readonly property string controlHoverFill: surfaceHover
    readonly property string controlHoverBorder: transparent
    readonly property string controlHoverText: textStrong
    readonly property string controlSelectedFill: surfaceActive
    readonly property string controlSelectedBorder: transparent
    readonly property string controlSelectedText: accent

    readonly property string tooltipFill: "#0C0C10"
    readonly property string tooltipBorder: borderStrong

    /* The fallback chain is resolved here against the installed families rather
     * than handed to Qt as a list, because QML's font value type takes one
     * family string and silently substitutes anything for an absent one. */
    readonly property string fontFamily: "FiraCode Nerd Font"
    readonly property string iconFontFamily: "FiraCode Nerd Font"
    readonly property string uiFontFamily: {
        const installed = Qt.fontFamilies();
        const wanted = ["Inter", "Noto Sans", "DejaVu Sans"];
        for (let i = 0; i < wanted.length; i++) {
            if (installed.indexOf(wanted[i]) !== -1) {
                return wanted[i];
            }
        }
        return root.fontFamily;
    }

    /* A manual override, normally left alone: every dimension below is logical
     * pixels, which Qt already maps to physical ones. HiDPI scaling comes from
     * quickshell-launch.sh translating Xft.dpi into QT_FONT_DPI, because Qt on
     * Xorg ignores Xft.dpi and reports a flat 96 DPI. That is also why this is
     * manual - on Xorg, Qt exposes QML no usable measure of physical density. */
    property real scale: 1.0

    function scaledSize(value) {
        return Math.max(1, Math.round(value * root.scale));
    }

    function scaledFontSize(value, minimum) {
        return Math.max(minimum, Math.round(value * root.scale));
    }

    readonly property int panelHeight: scaledSize(32)
    readonly property int panelMargin: 0
    readonly property int panelEdgeMargin: 0
    readonly property int panelSideMargin: scaledSize(14)
    readonly property int panelGap: scaledSize(6)
    readonly property int panelGroupGap: scaledSize(12)
    readonly property int barRadius: 0

    readonly property int barEdgeWidth: 1

    readonly property int pillRadius: scaledSize(5)
    readonly property int pillHeight: scaledSize(24)
    readonly property int pillHorizontalPadding: scaledSize(8)
    readonly property int pillBorderWidth: 1
    readonly property int smallRadius: scaledSize(5)

    readonly property int compactSpacing: scaledSize(5)
    readonly property int compactWidgetSize: scaledSize(24)
    readonly property int compactWidgetHorizontalPadding: scaledSize(7)

    readonly property int workspaceButtonSize: scaledSize(24)
    readonly property int trayItemSize: scaledSize(24)
    readonly property int trayIconSize: scaledSize(17)

    readonly property int underlineHeight: scaledSize(2)
    readonly property int underlineWidth: scaledSize(12)
    readonly property int occupiedMarkWidth: scaledSize(3)

    readonly property int separatorWidth: 1
    readonly property int separatorHeight: scaledSize(12)

    readonly property real titleWidthFraction: 0.18
    readonly property int titleMinWidth: scaledSize(120)

    readonly property real dockWidthFraction: 0.20
    readonly property int dockMinimumWidth: scaledSize(96)

    readonly property int panelFontSize: scaledFontSize(13, 10)
    readonly property int smallFontSize: scaledFontSize(12, 10)
    readonly property int tinyFontSize: scaledFontSize(10, 8)
    readonly property int panelIconFontSize: scaledFontSize(14, 8)

    readonly property real clockLetterSpacing: 0.8

    readonly property int animationNormal: 180
}
