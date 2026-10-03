import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool available: false
    property bool connected: false
    property string connectionType: ""
    property string statusText: "Network unavailable"

    readonly property string icon: {
        if (!root.connected) return "󰤭";
        if (root.connectionType === "ethernet") return "󰈀";
        return "󰤨";
    }

    function refresh() {
        if (!statusProcess.running) {
            statusProcess.running = true;
        }
    }

    function openEditor() {
        editorProcess.startDetached();
    }

    function parseDevices(text) {
        const lines = text.trim().split("\n");
        let deviceCount = 0;
        let connectedName = "";
        let connectedType = "";
        let firstType = "";

        for (const line of lines) {
            /* DEVICE:TYPE:STATE:CONNECTION */
            const fields = line.split(":");

            if (fields.length < 4 || fields[1] === "loopback") {
                continue;
            }

            deviceCount += 1;

            if (firstType.length === 0) {
                firstType = fields[1];
            }

            /* nmcli qualifies partial states - "connected (site only)",
             * "connected (externally)" - and those still count. */
            if (fields[2].indexOf("connected") === 0 && connectedName.length === 0) {
                connectedName = fields[3];
                connectedType = fields[1];
            }
        }

        root.available = deviceCount > 0;
        root.connected = connectedName.length > 0;
        root.connectionType = root.connected ? connectedType : firstType;
        root.statusText = !root.available ? "Network unavailable"
            : root.connected ? connectedName : "Offline";
    }

    Process {
        id: editorProcess

        command: ["nm-connection-editor"]
        running: false
    }

    Process {
        id: statusProcess

        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.parseDevices(this.text)
        }
    }

    Process {
        command: ["nmcli", "monitor"]
        running: true

        stdout: SplitParser {
            onRead: root.refresh()
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
