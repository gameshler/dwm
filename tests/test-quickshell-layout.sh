#!/bin/sh
# The layout and sharpness rules in SPEC.md's "User experience" section. Each
# names the defect it guards against.
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)

shell=$repo/config/quickshell
core=$shell/core
panel=$shell/panel
theme=$core/Theme.qml

# -- the title yields first -------------------------------------------------
# The only compressible thing in the left group. Without fillWidth a squeezed
# row overflows its own bounds and the title draws through the centre clock.
grep -Fq 'Layout.fillWidth: true' "$panel/DwmPanel.qml"
grep -Fq 'Layout.minimumWidth: 0' "$panel/DwmPanel.qml"
grep -Fq 'Layout.maximumWidth: Math.max(Theme.titleMinWidth,' "$panel/DwmPanel.qml"
grep -Fq 'elide: Text.ElideRight' "$panel/DwmPanel.qml"

# -- the dock has a ceiling -------------------------------------------------
# A share of the bar, so it means the same thing on a netbook and an ultrawide.
grep -Eq 'readonly property real dockWidthFraction: 0\.[0-9]+' "$theme"
grep -Eq 'readonly property real titleWidthFraction: 0\.[0-9]+' "$theme"
grep -Fq 'required property int maximumWidth' "$panel/RunningAppsArea.qml"
grep -Fq 'readonly property int shownCount:' "$panel/RunningAppsArea.qml"
grep -Fq 'readonly property int hiddenCount:' "$panel/RunningAppsArea.qml"
grep -Fq 'text: "+" + root.hiddenCount' "$panel/RunningAppsArea.qml"
grep -Fq 'maximumWidth: Math.max(Theme.dockMinimumWidth,' "$panel/DwmPanel.qml"

# Measured against the bar, not the space left over: the dock is part of what
# decides the space left over.
if grep -Fq 'maximumWidth: runningApps.parent.width' "$panel/DwmPanel.qml"; then
	printf 'The dock ceiling became circular.\n' >&2
	exit 1
fi

# -- the clock stays centred ------------------------------------------------
# A RowLayout hands each fillWidth item its minimum before splitting the
# surplus, so both sides must claim the same number.
grep -Fq 'readonly property int sideGroupMinimum:' "$panel/DwmPanel.qml"
[ "$(grep -c 'Layout.minimumWidth: root.sideGroupMinimum' "$panel/DwmPanel.qml")" -eq 2 ] || {
	printf 'Exactly two side groups must claim sideGroupMinimum.\n' >&2
	exit 1
}

# -- the status line is measured, not thresholded ---------------------------
# A width picked by hand is wrong in both directions.
if grep -rFq 'statusMinimumBarWidth' "$shell"; then
	printf 'The status line went back to a hand-picked width threshold.\n' >&2
	exit 1
fi
grep -Fq 'readonly property int statusNaturalWidth:' "$panel/DwmPanel.qml"
grep -Fq 'TextMetrics {' "$panel/DwmPanel.qml"
grep -Fq 'statusMetrics.advanceWidth' "$panel/DwmPanel.qml"
grep -Fq 'statusSlack.width' "$panel/DwmPanel.qml"
# From TextMetrics, not the row that draws it: a hidden RowLayout can stop
# reporting an implicit width, and the rule would then oscillate.
if grep -Fq 'visible: root.statusNaturalWidth > 0 && statusGroup.implicitWidth' \
	"$panel/DwmPanel.qml"; then
	printf 'The status fit reads the row it controls.\n' >&2
	exit 1
fi

# -- sharpness --------------------------------------------------------------
# NativeRendering is sharpest, but only while one logical pixel is a whole
# number of physical ones. Qt 6 defaults to PassThrough rounding, so a laptop at
# 150% hands the bar a ratio of 1.5 and hinting produces, in Qt's own words,
# "poor and sometimes pixelated results".
grep -Fq 'readonly property real devicePixelRatio: Screen.devicePixelRatio' "$core/UiText.qml"
grep -Fq 'readonly property bool pixelAligned:' "$core/UiText.qml"
grep -Fq 'renderType: root.pixelAligned ? Text.NativeRendering : Text.QtRendering' \
	"$core/UiText.qml"

# The rule has to live in exactly one place.
if grep -REn 'renderType:' "$shell" | grep -v '/core/UiText.qml:'; then
	printf 'A renderType escaped core/UiText.qml.\n' >&2
	exit 1
fi
grep -Fq 'UiText {' "$core/ProseText.qml"

# Qt sizes a layer texture in logical pixels, so without this the greyscale
# layer renders at the logical size and is stretched to fill the physical one.
grep -Fq 'layer.textureSize: Qt.size(' "$panel/RunningAppItem.qml"
grep -Fq 'Screen.devicePixelRatio' "$panel/RunningAppItem.qml"
# Papirus ships these at 64px and up and the bar draws them at 17.
grep -Fq 'mipmap: true' "$panel/RunningAppItem.qml"
grep -Fq 'mipmap: true' "$panel/TrayItem.qml"

# -- multi-monitor ----------------------------------------------------------
# dwm reports monitor geometry in physical pixels, so the origin has to scale by
# the same ratio as the size or every monitor except the one at x=0 falls
# through to matching by ordering.
grep -Fq 'const pixelX = screen ? Math.round(screen.x * pixelRatio) : 0;' \
	"$shell/state/DwmState.qml"
grep -Fq 'const pixelY = screen ? Math.round(screen.y * pixelRatio) : 0;' \
	"$shell/state/DwmState.qml"

printf 'Quickshell layout and sharpness contract: PASS\n'
