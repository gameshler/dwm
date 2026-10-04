pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

/* Two plain text files, one line per bookmark, in either of two shapes:
 *
 *   https://youtube.com                        title taken from the host
 *   Arch Wiki :: https://wiki.archlinux.org    title given explicitly
 *
 * Blank lines and lines starting with # are skipped. The file a bookmark came
 * from decides which browser opens it, which is the whole point of there being
 * two of them. */
MenuModel {
    id: root

    property string personalText: ""
    property string workText: ""

    title: "Bookmarks"
    placeholder: "Open a bookmark"

    function hostTitle(url) {
        const withoutScheme = url.replace(/^[a-z]+:\/\//i, "");
        const host = withoutScheme.split("/")[0].replace(/^www\./i, "");
        const label = host.split(".")[0];
        return label.length > 0 ? label : url;
    }

    function parseFile(text, tag, rows) {
        for (const line of text.split("\n")) {
            const entry = line.trim();
            if (entry.length === 0 || entry.indexOf("#") === 0) {
                continue;
            }

            const marker = entry.indexOf("::");
            const label = marker === -1
                ? root.hostTitle(entry) : entry.substring(0, marker).trim();
            const url = marker === -1 ? entry : entry.substring(marker + 2).trim();

            if (url.length === 0) {
                continue;
            }

            rows.push({
                "key": tag + "\t" + url,
                "label": label,
                "detail": url,
                "icon": tag === "work" ? "󰃖" : "󰓹"
            });
        }
    }

    entries: {
        const rows = [];
        root.parseFile(root.personalText, "personal", rows);
        root.parseFile(root.workText, "work", rows);
        return rows;
    }

    onActivated: function (key) {
        const split = key.indexOf("\t");
        openProcess.command = ["dwm-bookmark-open", key.substring(0, split),
            key.substring(split + 1)];
        openProcess.startDetached();
    }

    /* Watched rather than read once: editing the file should change the menu
     * without restarting the bar. */
    FileView {
        path: Quickshell.env("HOME") + "/.config/bookmarks/personal.txt"
        watchChanges: true
        onLoaded: root.personalText = this.text()
        onLoadFailed: root.personalText = ""
        onFileChanged: this.reload()
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/bookmarks/work.txt"
        watchChanges: true
        onLoaded: root.workText = this.text()
        onLoadFailed: root.workText = ""
        onFileChanged: this.reload()
    }

    Process {
        id: openProcess

        running: false
    }
}
