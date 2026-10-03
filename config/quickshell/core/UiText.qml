import QtQuick
import qs.core

/* The renderType rule for every piece of text on the bar, and the only place
 * it is allowed to live. NativeRendering hints glyphs onto the physical pixel
 * grid, but Qt documents it as pixelated under a fractional transform, which
 * Qt 6's PassThrough rounding policy makes routine. So: hint when one logical
 * pixel is a whole number of physical ones, use QtRendering otherwise. */
Text {
    id: root

    readonly property real devicePixelRatio: Screen.devicePixelRatio
    readonly property bool pixelAligned:
        Math.abs(root.devicePixelRatio - Math.round(root.devicePixelRatio)) < 0.01

    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.panelFontSize
    renderType: root.pixelAligned ? Text.NativeRendering : Text.QtRendering
    verticalAlignment: Text.AlignVCenter
}
