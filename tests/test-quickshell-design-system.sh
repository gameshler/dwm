#!/bin/sh
# The design rules in core/Theme.qml, asserted rather than described: a token
# that quietly disappears or changes meaning is a visual regression everywhere
# at once and in no single place.
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)

shell=$repo/config/quickshell
core=$shell/core
theme=$core/Theme.qml

# Every token something on the bar reads. The list is the contract.
for token in \
	transparent bg barBackground surface surfaceHover surfaceActive \
	border borderStrong text textStrong textMuted \
	accent accentSecondary danger warning success \
	controlNormalFill controlNormalBorder controlNormalText \
	controlHoverFill controlHoverBorder controlHoverText \
	controlSelectedFill controlSelectedBorder controlSelectedText \
	tooltipFill tooltipBorder fontFamily iconFontFamily uiFontFamily \
	panelHeight panelSideMargin panelGap panelGroupGap barEdgeWidth \
	pillRadius pillHeight pillHorizontalPadding pillBorderWidth smallRadius \
	compactSpacing compactWidgetSize compactWidgetHorizontalPadding \
	workspaceButtonSize trayItemSize trayIconSize \
	underlineHeight underlineWidth occupiedMarkWidth \
	separatorWidth separatorHeight \
	titleWidthFraction titleMinWidth dockWidthFraction dockMinimumWidth \
	panelFontSize smallFontSize tinyFontSize panelIconFontSize \
	clockLetterSpacing animationNormal; do
	grep -Eq "readonly property (string|int|real) $token:" "$theme" || {
		printf 'Theme token is missing: %s\n' "$token" >&2
		exit 1
	}
done

# The one deliberately writable property: the manual scale override.
grep -Eq '^[[:space:]]*property real scale: 1\.0$' "$theme"

# Black, not near-black: the bar is meant to disappear into the wallpaper.
grep -Eq 'readonly property string bg: "#000000"' "$theme"
grep -Eq 'readonly property string barBackground: "#000000"' "$theme"

# Nothing draws a box at rest.
grep -Eq 'readonly property string controlNormalFill: transparent' "$theme"
grep -Eq 'readonly property string controlNormalBorder: transparent' "$theme"

# Resolved against the installed families, because QML's font value type has
# only family, not families, and substitutes silently for an absent one.
grep -Fq 'Qt.fontFamilies()' "$theme"
grep -Fq 'return root.fontFamily;' "$theme"

# Theme is the only place a literal colour may appear.
if grep -REn --include='*.qml' '"#[0-9A-Fa-f]{6,8}"' "$shell" | grep -v '/core/Theme.qml:'; then
	printf 'A colour literal escaped Theme.qml.\n' >&2
	exit 1
fi

# An Xorg build: a Wayland or Hyprland import compiles fine and fails at
# runtime.
if grep -REn \
	-e 'Quickshell\.(Wayland|Hyprland)' \
	-e 'WlrLayershell' \
	-e '(^|[^[:alnum:]_-])(hyprctl|uwsm-app|wl-copy|wl-paste)([^[:alnum:]_-]|$)' \
	"$shell"; then
	printf 'The bar picked up a Wayland or Hyprland dependency.\n' >&2
	exit 1
fi

printf 'Quickshell design system: PASS\n'
