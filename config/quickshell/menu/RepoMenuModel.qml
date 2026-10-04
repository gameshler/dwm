pragma ComponentBehavior: Bound

import Quickshell.Io

/* Every directory one level under ~/projects, opened in a terminal running
 * tmux and nvim. Listed on open rather than once at startup, because a project
 * cloned since the bar started should be in the list without restarting it. */
MenuModel {
    id: root

    title: "Projects"
    placeholder: "Open a project"

    function reload() {
        if (!listProcess.running) {
            listProcess.running = true;
        }
    }

    function parseList(text) {
        const rows = [];

        for (const line of text.split("\n")) {
            const path = line.trim();
            if (path.length === 0) {
                continue;
            }

            const name = path.substring(path.lastIndexOf("/") + 1);
            rows.push({ "key": path, "label": name, "detail": path, "icon": "󰉋" });
        }

        root.entries = rows;
        root.present();
    }

    onActivated: function (key) {
        openProcess.command = ["dwm-repo-open", key];
        openProcess.startDetached();
    }

    Process {
        id: listProcess

        /* find, not ls: a directory whose name contains a space still arrives
         * as one line. -mindepth/-maxdepth 1 keeps it to the projects
         * themselves rather than everything inside them. */
        command: ["sh", "-c",
            "dir=\"${DWM_PROJECTS_DIR:-$HOME/projects}\"; mkdir -p \"$dir\"; "
            + "find \"$dir\" -mindepth 1 -maxdepth 1 -type d | sort"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseList(this.text)
        }
    }

    Process {
        id: openProcess

        running: false
    }
}
