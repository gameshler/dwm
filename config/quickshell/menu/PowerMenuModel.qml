pragma ComponentBehavior: Bound

import Quickshell.Io

MenuModel {
    id: root

    /* The sleep states this kernel will accept: "mem" is suspend-to-RAM, "disk"
     * is hibernate. Hibernate also needs swap at least the size of RAM and a
     * resume= kernel parameter, which only systemd can judge, so this gate is
     * necessary rather than sufficient - a machine that passes it can still
     * refuse, and the helper reports that when it happens. */
    property string powerStates: ""

    function supports(state) {
        /* An unreadable or empty list proves nothing - a container masks the
         * file entirely - so offer the entry rather than withdrawing one that
         * works today. Only a list that was read and does not name the state
         * hides it. */
        if (root.powerStates.trim().length === 0) {
            return true;
        }

        return (" " + root.powerStates.trim() + " ").indexOf(" " + state + " ") !== -1;
    }

    title: "Power"
    menuIcon: "󰐥"
    placeholder: "logout, suspend, reboot..."
    emptyText: "No such session action"

    entries: {
        const rows = [
            { "key": "logout", "label": "Log out", "detail": "End the session", "icon": "󰍃" }
        ];

        if (root.supports("mem")) {
            rows.push({ "key": "suspend", "label": "Suspend", "detail": "Sleep to RAM", "icon": "󰤄" });
        }

        if (root.supports("disk")) {
            rows.push({ "key": "hibernate", "label": "Hibernate", "detail": "Sleep to disk", "icon": "󰒲" });
        }

        rows.push({ "key": "reboot", "label": "Restart", "detail": "Reboot now", "icon": "󰜉" });
        rows.push({ "key": "poweroff", "label": "Shut down", "detail": "Power off now", "icon": "󰐥" });
        return rows;
    }

    onActivated: function (key) {
        actionProcess.command = ["dwm-session-action", key];
        actionProcess.running = true;
    }

    FileView {
        path: "/sys/power/state"
        onLoaded: root.powerStates = this.text()
        onLoadFailed: root.powerStates = ""
    }

    Process {
        id: actionProcess

        running: false
        stderr: StdioCollector {
            onStreamFinished: {
                const reason = this.text.trim();
                if (reason.length > 0) {
                    root.fail(reason);
                }
            }
        }
    }
}
