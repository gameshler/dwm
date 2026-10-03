import QtQuick
import Quickshell
import Quickshell.Io

/* checkupdates (pacman-contrib) syncs a private copy of the package database,
 * so it never leaves the real one half-synced. It does reach the network, which
 * nothing else here does at runtime; recorded in SPEC.md. The pacman -Qu
 * fallback is offline and only as fresh as the last sync the user ran. */
Scope {
    id: root

    property bool available: false
    property int count: 0

    readonly property string icon: "󰚰"
    readonly property string statusText: !root.available ? "Updates unavailable"
        : root.count === 0 ? "System up to date"
        : root.count === 1 ? "1 update available"
        : root.count + " updates available"

    function refresh() {
        if (!checkProcess.running) {
            checkProcess.running = true;
        }
    }

    function openUpdater() {
        updateProcess.startDetached();
    }

    function parseCount(text) {
        const trimmed = text.trim();

        if (trimmed === "unavailable") {
            root.available = false;
            root.count = 0;
            return;
        }

        const parsed = parseInt(trimmed, 10);

        root.available = !isNaN(parsed);
        root.count = isNaN(parsed) ? 0 : parsed;
    }

    Process {
        id: checkProcess

        command: ["sh", "-c",
            "if command -v checkupdates >/dev/null 2>&1; then checkupdates | wc -l; "
            + "elif command -v pacman >/dev/null 2>&1; then pacman -Qu 2>/dev/null | wc -l; "
            + "else echo unavailable; fi"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.parseCount(this.text)
        }
    }

    Process {
        id: updateProcess

        command: ["ghostty", "-e", "sh", "-c",
            "sudo pacman -Syu; printf '\\nPress enter to close '; read -r _"]
        running: false
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
