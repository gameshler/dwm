import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.core

RowLayout {
    id: root

    readonly property var items: SystemTray.items.values

    visible: root.items.length > 0
    spacing: Theme.compactSpacing

    Repeater {
        model: root.items

        delegate: TrayItem {
            required property var modelData

            trayItem: modelData
        }
    }
}
