pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/* What the bar menus have in common: a list that filters as it is typed
 * into, a selection that survives the filtering, and one activation signal. A
 * concrete menu extends this, fills entries, and handles activated().
 *
 * `shown` rather than `visible`: this is not an Item, and a property named
 * visible on a non-visual type reads like it should draw something. */
Scope {
    id: root

    /* [{ key, label, detail, icon, iconSource }]. key is what activated()
     * reports, and is the only field a concrete menu has to give meaning to.
     * icon is a glyph from the icon font; iconSource is an image path, for a
     * row that has a real icon of its own. A row sets one or the other, and the
     * glyph is what shows when an image path does not resolve. */
    property var entries: []
    property string title: "Menu"
    /* The glyph beside the search field. A menu opened from a keybinding gives
     * no other clue which one arrived. */
    property string menuIcon: "󰍉"
    property string placeholder: "Type to filter"
    property string emptyText: "No matches"
    /* Which end of a too-long detail to drop. A path or a URL is identified by
     * its tail, so the default keeps that; a menu whose detail is a sentence
     * overrides it, because left-eliding English reads as damage. */
    property int detailElide: Text.ElideLeft
    property string query: ""
    /* Shown under the list. Set by a menu whose action failed, which is the
     * only way the user hears about it: these are started detached from the
     * bar, so stderr goes nowhere anyone will read. */
    property string message: ""
    property bool shown: false
    property int selectedIndex: 0

    signal activated(string key)

    readonly property var rows: {
        const needle = root.query.trim().toLowerCase();
        if (needle.length === 0) {
            return root.entries;
        }

        return root.entries.filter(function (entry) {
            const haystack = entry.label + " " + (entry.detail || "");
            return haystack.toLowerCase().indexOf(needle) !== -1;
        });
    }

    /* Clamped rather than reset, so narrowing the filter keeps the selection on
     * a row near where it was instead of jumping back to the top. rows does not
     * read selectedIndex, so this cannot feed back. */
    onRowsChanged: root.selectedIndex = root.rows.length > 0
        ? Math.max(0, Math.min(root.selectedIndex, root.rows.length - 1))
        : 0

    /* Overridden by a menu whose entries come from outside the shell, so a list
     * is never older than the moment the menu was opened. An override must call
     * present() once its entries have landed, and not before: dwm sizes a
     * floating window when it maps it, so a menu shown while its list is still
     * loading is left the height of an empty one. */
    function reload() {
        root.present();
    }

    function present() {
        root.shown = true;
    }

    function open() {
        root.query = "";
        root.message = "";
        root.selectedIndex = 0;
        root.reload();
    }

    function close() {
        root.shown = false;
    }

    function toggle() {
        if (root.shown) {
            root.close();
        } else {
            root.open();
        }
    }

    function move(delta) {
        const count = root.rows.length;
        if (count === 0) {
            return;
        }

        root.selectedIndex = (root.selectedIndex + delta + count) % count;
    }

    function activateIndex(index) {
        if (index < 0 || index >= root.rows.length) {
            return;
        }

        const key = root.rows[index].key;
        root.close();
        root.activated(key);
    }

    function activateSelected() {
        root.activateIndex(root.selectedIndex);
    }

    /* Reopens the menu to carry the reason. An action that failed silently is
     * indistinguishable from a menu that did nothing, which is exactly the
     * complaint this whole surface exists to answer. */
    function fail(text) {
        root.message = text;
        root.query = "";
        root.shown = true;
    }
}
