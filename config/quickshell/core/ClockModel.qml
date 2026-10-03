import QtQuick
import Quickshell

Scope {
    id: root

    property string panelText: ""

    function refreshDisplay() {
        root.panelText = Qt.formatDateTime(source.date, "ddd dd MMM - HH:mm");
    }

    Component.onCompleted: root.refreshDisplay()

    SystemClock {
        id: source

        precision: SystemClock.Minutes
        onDateChanged: root.refreshDisplay()
    }
}
