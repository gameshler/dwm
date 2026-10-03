pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    required property var desktopState
    /* Zero means no ceiling. */
    required property int maximumWidth

    readonly property var apps: root.desktopState.runningApps
    readonly property int stride: Theme.pillHeight + Theme.panelGap

    /* n icons occupy n * stride - panelGap, because the last carries no
     * trailing gap; adding panelGap back to the budget accounts for that. */
    readonly property int shownCount: {
        const total = root.apps.length;
        if (total === 0 || root.maximumWidth <= 0) {
            return total;
        }
        const fits = Math.floor((root.maximumWidth + Theme.panelGap) / root.stride);
        if (fits >= total) {
            return total;
        }
        return Math.max(0, fits - 1);
    }
    readonly property int hiddenCount: root.apps.length - root.shownCount

    implicitWidth: appRow.implicitWidth
    implicitHeight: Theme.pillHeight

    RowLayout {
        id: appRow

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.panelGap

        Repeater {
            model: root.apps.slice(0, root.shownCount)

            delegate: RunningAppItem {
                required property var modelData

                app: modelData
                active: modelData.appClass === root.desktopState.activeWindowClass
                onFocusRequested: windowId => root.desktopState.focusWindow(windowId)
            }
        }

        /* Not an icon: the number of windows there was no room to draw. */
        UiText {
            Layout.alignment: Qt.AlignVCenter
            visible: root.hiddenCount > 0
            text: "+" + root.hiddenCount
            color: Theme.textMuted
            font.pixelSize: Theme.smallFontSize
        }
    }
}
