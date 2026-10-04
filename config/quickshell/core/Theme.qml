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

    /* The header above says fills and borders exist only for hover and
     * selection. They were too dark to do that job. Against the #000000 bar:
     *
     *   surfaceHover    #26262F   1.40:1   was #17171D at 1.18:1 - hovering a
     *                                      tag, a dock icon or a pill lit a
     *                                      rectangle nobody could see, so the
     *                                      bar read as having no hover at all
     *   surfaceActive   #33333F   1.69:1   was #1E1E26 at 1.27:1. Reachable
     *                                      only through PanelPill.active,
     *                                      which nothing sets today, so this
     *                                      moves to stay one step above hover
     *   border          #26262F   1.40:1   was #1A1A20 at 1.21:1. This draws
     *                                      the separators and the bar's bottom
     *                                      edge, both of which sat on a black
     *                                      wallpaper and vanished into it
     *   borderStrong    #3A3A48   1.88:1   was #2E2E3A at 1.57:1. The tooltip
     *                                      outline, over application windows
     *                                      rather than over the bar
     *
     * Still dark enough that nothing draws a box at rest - every one of these
     * appears on hover or as a hairline. surface has no reference at all; it
     * moves with the ramp so it stays coherent if something reaches for it. */
    readonly property string surface: "#15151B"
    readonly property string surfaceHover: "#26262F"
    readonly property string surfaceActive: "#33333F"

    readonly property string border: "#26262F"
    readonly property string borderStrong: "#3A3A48"

    /* Contrast against the #000000 bar, measured as a WCAG ratio:
     *
     *   text        #8A8A96   6.2:1   was #70707C at 4.3:1, under the 4.5:1
     *                                 floor for body text - and this is the
     *                                 window title, the status line and every
     *                                 inactive icon, so it is the colour that
     *                                 is read most and strained for
     *   textStrong  #E8E8EC  17.2:1   unchanged
     *   textMuted   #4E4E5A   2.6:1   was #3E3E48 at 2.0:1. Decorative: an
     *                                 empty tag, the +n overflow count. Below
     *                                 the floor on purpose, since reading it
     *                                 is never the point, but legible enough
     *                                 to be seen at all
     *   accent      #88C0D0  10.5:1   unchanged
     *
     * The hierarchy is unchanged - strong, normal, muted still separate
     * cleanly. Only the bottom two were dark enough to hurt. */
    readonly property string text: "#8A8A96"
    readonly property string textStrong: "#E8E8EC"
    readonly property string textMuted: "#4E4E5A"

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

    /* Two rules govern every number below, and both of them are about pixels
     * landing on pixels.
     *
     * An icon is centred by its container, so a container and an icon of
     * different parity put the icon on a half pixel and Qt resamples it into a
     * blur. trayIconSize was 17 inside a 24 box: an offset of 3.5, every icon
     * on the bar soft. Every icon size here is even and every box that holds
     * one is even, so the margin is whole.
     *
     * The icon sizes are also the ones the icon theme actually draws. Papirus
     * ships 16, 22, 24, 32, 48 and 64; asking for 17 made it resample 22 down
     * by a fraction. 22 is drawn as authored.
     *
     * Both hold at scale 1.0, which is the default and the only value tuned.
     * A fractional scale will reintroduce fractional sizes - that is the
     * trade the override accepts. */
    readonly property int panelHeight: scaledSize(40)
    readonly property int panelMargin: 0
    readonly property int panelEdgeMargin: 0
    readonly property int panelSideMargin: scaledSize(16)
    readonly property int panelGap: scaledSize(8)
    readonly property int panelGroupGap: scaledSize(14)
    readonly property int barRadius: 0

    readonly property int barEdgeWidth: 1

    readonly property int pillRadius: scaledSize(6)
    readonly property int pillHeight: scaledSize(30)
    readonly property int pillHorizontalPadding: scaledSize(10)
    readonly property int pillBorderWidth: 1
    readonly property int smallRadius: scaledSize(6)

    readonly property int compactSpacing: scaledSize(6)
    readonly property int compactWidgetSize: scaledSize(30)
    readonly property int compactWidgetHorizontalPadding: scaledSize(8)

    readonly property int workspaceButtonSize: scaledSize(30)
    readonly property int trayItemSize: scaledSize(30)
    readonly property int trayIconSize: scaledSize(22)

    readonly property int underlineHeight: scaledSize(2)
    readonly property int underlineWidth: scaledSize(16)
    readonly property int occupiedMarkWidth: scaledSize(4)

    readonly property int separatorWidth: 1
    readonly property int separatorHeight: scaledSize(16)

    readonly property real titleWidthFraction: 0.18
    readonly property int titleMinWidth: scaledSize(150)

    readonly property real dockWidthFraction: 0.20
    readonly property int dockMinimumWidth: scaledSize(120)

    readonly property int panelFontSize: scaledFontSize(15, 10)
    readonly property int smallFontSize: scaledFontSize(14, 10)
    readonly property int tinyFontSize: scaledFontSize(11, 8)
    readonly property int panelIconFontSize: scaledFontSize(17, 8)

    /* Whole pixels. NativeRendering places glyphs on the pixel grid, so a
     * fractional tracking value put every character after the first on a
     * fraction and softened the one label that is always on screen. */
    readonly property real clockLetterSpacing: 1.0

    /* The menus. Width is fixed rather than a fraction of the screen so the
     * same list does not reflow between the 1080p and 1440p panel, and every
     * value is even for the same centring reason as the bar above.
     *
     * menuIconSize is 24 because that is a size Papirus authors; see the icon
     * note above. menuRowHeight is 24 + 2 * 9, so the centring margin on a row
     * is whole, and menuFieldHeight matches it so the field and the first row
     * read as the same rhythm. */
    readonly property int menuWidth: scaledSize(560)
    readonly property int menuRowHeight: scaledSize(42)
    readonly property int menuPadding: scaledSize(14)
    readonly property int menuSpacing: scaledSize(4)
    readonly property int menuGap: scaledSize(10)
    readonly property int menuFieldHeight: scaledSize(42)
    readonly property int menuIconSize: scaledSize(24)
    readonly property int menuMaxRows: 9
    readonly property int menuRadius: scaledSize(12)
    readonly property int menuRowRadius: scaledSize(8)
    readonly property int menuFooterHeight: scaledSize(18)
    readonly property int menuScrollWidth: scaledSize(3)
    /* The selected row's left mark. The bar marks a focused tag with an
     * underline; a list marks its selection down the leading edge instead,
     * because that is the edge the eye tracks while the keys move. */
    readonly property int menuMarkWidth: scaledSize(3)
    readonly property real menuMarkFraction: 0.5

    /* Darker than tooltipFill, which sits over application windows and has to
     * separate from them. A menu is the only thing on screen that matters while
     * it is open, so it goes the other way: the panel recedes and the search
     * field is the one surface that reads as raised. */
    readonly property string menuFill: "#07070A"
    readonly property string menuBorder: borderStrong
    readonly property string menuFieldFill: surface
    readonly property string menuFieldBorder: border

    readonly property int animationNormal: 180
}
