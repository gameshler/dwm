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

    /* Local package changes, noticed as they happen. pacman appends to this on
     * every transaction, so an install, a removal or a -Syu all land here and
     * the count stops sitting stale until the next half-hourly sweep.
     *
     * preload is off and neither text() nor data() is ever called, so the file
     * is watched without being read - this log reaches tens of megabytes on an
     * old install and none of its content is wanted, only the fact that it
     * moved. A missing file simply never fires, which is the right answer off
     * Arch. */
    FileView {
        path: "/var/log/pacman.log"
        preload: false
        watchChanges: true
        onFileChanged: settleTimer.restart()
    }

    /* A transaction writes many lines over however long it takes, and
     * checkupdates syncs a database over the network, so it is worth running
     * once after the writing stops rather than on every line. */
    Timer {
        id: settleTimer

        interval: 1500
        onTriggered: root.refresh()
    }

    /* Still needed with the watcher in place: updates appear when a remote
     * repository gains a package, which happens with nothing at all going on
     * locally. */
    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
