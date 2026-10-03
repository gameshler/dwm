#!/bin/sh
set -eu

# The display manager starts dwm with a PATH that excludes ~/.local/bin, where
# dwm-quickshell-state lives and where the bar shells out to find it.
PATH="$HOME/.local/bin:$PATH"
export PATH

command -v quickshell >/dev/null 2>&1 || {
	printf 'ERROR: quickshell is not installed\n' >&2
	exit 1
}

command -v xprop >/dev/null 2>&1 || {
	printf 'ERROR: xprop (xorg-xprop) is required by dwm-quickshell-state\n' >&2
	exit 1
}

command -v wmctrl >/dev/null 2>&1 ||
	printf 'WARNING: wmctrl is missing; clicking tags and apps in the bar will do nothing\n' >&2

# Without a platform theme Qt resolves no icon theme, so every tray and
# running-app icon comes up blank. gtk3 follows the icon theme already set for
# GTK; the gnome theme built into qtbase is the fallback.
if [ -z "${QT_QPA_PLATFORMTHEME:-}" ]; then
	QT_QPA_PLATFORMTHEME=gnome
	for dir in /usr/lib/qt6/plugins/platformthemes /usr/lib/qt/plugins/platformthemes; do
		if [ -e "$dir/libqgtk3.so" ]; then
			QT_QPA_PLATFORMTHEME=gtk3
			break
		fi
	done
	export QT_QPA_PLATFORMTHEME
fi

# Translate Xft.dpi into QT_FONT_DPI so a single value in ~/.Xresources scales
# the whole desktop. Xft.dpi already sizes dwm's font, client titles and rofi,
# but Qt on xcb assumes a flat 96 and ignores both Xft.dpi and the dimensions
# the X server reports; QT_FONT_DPI is the only knob that moves it. Skipped
# when either Qt variable is already set, so .xprofile still wins.
if [ -z "${QT_FONT_DPI:-}" ] && [ -z "${QT_SCALE_FACTOR:-}" ] &&
	command -v xrdb >/dev/null 2>&1; then
	xft_dpi=$(xrdb -query 2>/dev/null | awk '/^Xft\.dpi:/ { print $2; exit }')
	case "$xft_dpi" in
	'' | *[!0-9]*) ;;
	*)
		# Below 96 nothing needs scaling; past 384 the value is junk.
		if [ "$xft_dpi" -gt 96 ] && [ "$xft_dpi" -le 384 ]; then
			QT_FONT_DPI="$xft_dpi"
			export QT_FONT_DPI
		fi
		;;
	esac
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$HOME/.config/quickshell/shell.qml" ]; then
	CONFIG_DIR="$HOME/.config/quickshell"
elif [ -f "$SCRIPT_DIR/../config/quickshell/shell.qml" ]; then
	CONFIG_DIR="$SCRIPT_DIR/../config/quickshell"
else
	printf 'ERROR: no shell.qml found in ~/.config/quickshell\n' >&2
	exit 1
fi

exec quickshell --path "$CONFIG_DIR" --no-duplicate
