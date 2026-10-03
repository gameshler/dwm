import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool available: false
    property bool powered: false
    property string adapterName: ""

    readonly property string icon: root.powered ? "󰂯" : "󰂲"
    readonly property string statusText: !root.available ? "No bluetooth adapter"
        : !root.powered ? "Bluetooth off"
        : root.adapterName.length > 0 ? root.adapterName : "Bluetooth on"

    function parseShow(text) {
        const poweredMatch = text.match(/^\s*Powered:\s*(\S+)/m);
        const nameMatch = text.match(/^\s*Name:\s*(.+)$/m);

        root.available = poweredMatch !== null;
        root.powered = root.available && poweredMatch[1] === "yes";
        root.adapterName = root.available && nameMatch !== null ? nameMatch[1].trim() : "";
    }

    Process {
        id: showProcess

        command: ["bluetoothctl", "show"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.parseShow(this.text)
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: {
            if (!showProcess.running) {
                showProcess.running = true;
            }
        }
    }
}
