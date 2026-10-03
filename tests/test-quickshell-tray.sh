#!/bin/sh
# The system tray, and the two things that keep going wrong with it.
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)

shell=$repo/config/quickshell
panel=$shell/panel

# One tray host only: a second would race the first for the
# StatusNotifierWatcher bus name, so it is loaded on the primary panel alone.
grep -Fq 'required property bool primaryPanel' "$panel/DwmPanel.qml"
grep -Fq 'active: root.primaryPanel' "$panel/DwmPanel.qml"
grep -Fq 'sourceComponent: TrayArea {}' "$panel/DwmPanel.qml"
grep -Fq 'primaryPanel: modelData === Quickshell.screens[0]' "$shell/shell.qml"

grep -Fq 'import Quickshell.Services.SystemTray' "$panel/TrayArea.qml"
grep -Fq 'readonly property var items: SystemTray.items.values' "$panel/TrayArea.qml"
grep -Fq 'model: root.items' "$panel/TrayArea.qml"
grep -Fq 'trayItem: modelData' "$panel/TrayArea.qml"
# Nothing at all when the tray is empty.
grep -Fq 'visible: root.items.length > 0' "$panel/TrayArea.qml"

# A tray item advertises several icon names and not all resolve, so the item
# walks its candidates on load failure and falls back to a placeholder.
grep -Fq 'property var iconSources: Icons.trayIconSources(root.trayItem)' "$panel/TrayItem.qml"
grep -Fq 'status === Image.Error' "$panel/TrayItem.qml"
grep -Fq 'root.iconSourceIndex += 1;' "$panel/TrayItem.qml"
grep -Fq 'visible: !trayIcon.visible' "$panel/TrayItem.qml"
# Middle and right click both carry tray menu semantics.
grep -Fq 'Qt.LeftButton | Qt.MiddleButton | Qt.RightButton' "$panel/TrayItem.qml"

# The app dock and the tray are different things; folding one into the other
# loses every tray-only application.
if grep -Fq 'SystemTray' "$panel/RunningAppsArea.qml" ||
	grep -Fq 'trayItems' "$panel/RunningAppItem.qml"; then
	printf 'The running-window dock must not replace the independent tray.\n' >&2
	exit 1
fi

printf 'Quickshell system tray: PASS\n'
