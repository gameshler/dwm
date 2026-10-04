pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.core

/* Every installed application, read from the XDG desktop entries. DesktopEntries
 * already drops the ones marked Hidden or NoDisplay, so what is listed here is
 * what the system says a user is meant to be able to start.
 *
 * Live rather than listed on open: DesktopEntries watches the entry directories
 * itself, so an application installed since the bar started is already in the
 * list and reload() has nothing to do. */
MenuModel {
    id: root

    /* The terminal a Terminal=true entry is wrapped in. Same override name the
     * other helpers use, so one variable in .xprofile covers the desktop. */
    readonly property string terminal: {
        const configured = Quickshell.env("DWM_TERMINAL");
        return configured && configured.length > 0 ? configured : "ghostty";
    }

    title: "Apps"
    menuIcon: "󰀻"
    placeholder: "Run an application"
    emptyText: "No application matches"
    detailElide: Text.ElideRight

    entries: {
        const rows = [];
        const applications = DesktopEntries.applications.values;

        for (let index = 0; index < applications.length; index++) {
            const application = applications[index];
            const name = application.name || application.id;

            rows.push({
                "key": application.id,
                "label": name,
                /* genericName is the short "Web Browser" line; comment is the
                 * longer tooltip. Either tells the user which of two similarly
                 * named entries they are about to start. */
                "detail": application.genericName || application.comment || "",
                /* The glyph is what shows when the icon theme has nothing for
                 * this entry, which is routine for daemons and for anything
                 * installed outside a theme's coverage. */
                "icon": "󰣆",
                "iconSource": Icons.applicationIcon(application.icon || "")
            });
        }

        rows.sort(function (left, right) {
            return left.label.toLowerCase() < right.label.toLowerCase() ? -1 : 1;
        });

        return rows;
    }

    onActivated: function (key) {
        const application = DesktopEntries.byId(key);

        if (application === null) {
            root.fail("No desktop entry named " + key);
            return;
        }

        /* DesktopEntry.command is documented as not invoking a terminal even
         * when the entry asks for one, and execute() runs that command, so a
         * Terminal=true entry has to be wrapped here. Without this, a TUI
         * application started from the menu gets no tty and exits at once. */
        if (application.runInTerminal) {
            const command = [root.terminal, "-e"];

            for (let index = 0; index < application.command.length; index++) {
                command.push(application.command[index]);
            }

            Quickshell.execDetached({
                "command": command,
                "workingDirectory": application.workingDirectory
            });
            return;
        }

        application.execute();
    }
}
