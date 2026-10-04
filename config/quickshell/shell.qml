//@ pragma UseQApplication

pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import qs.core
import qs.menu
import qs.panel
import qs.services
import qs.state

ShellRoot {
    id: root

    /* Only ever one menu open: they all want the keyboard, and dwm gives it to
     * whichever window mapped last. Opening one closes the others rather than
     * racing them. */
    readonly property var menus: [appMenu, powerMenu, repoMenu, bookmarkMenu]

    function openMenu(menu) {
        for (let index = 0; index < root.menus.length; index++) {
            if (root.menus[index] !== menu) {
                root.menus[index].close();
            }
        }

        menu.open();
    }

    function toggleMenu(menu) {
        if (menu.shown) {
            menu.close();
        } else {
            root.openMenu(menu);
        }
    }

    DwmState {
        id: dwmState
    }

    ClockModel {
        id: clock
    }

    AudioModel {
        id: audioModel
    }

    BatteryModel {
        id: batteryModel
    }

    BluetoothModel {
        id: bluetoothModel
    }

    NetworkModel {
        id: networkModel
    }

    UpdateModel {
        id: updateModel
    }

    AppMenuModel {
        id: appMenu
    }

    PowerMenuModel {
        id: powerMenu
    }

    RepoMenuModel {
        id: repoMenu
    }

    BookmarkMenuModel {
        id: bookmarkMenu
    }

    /* A LazyLoader each, rather than one window switched between menus: dwm
     * fixes a floating client's geometry when it first manages it, so a reused
     * window kept whatever height the first menu to open happened to need.
     * Destroying it on close means the next menu arrives as a new window, sized
     * to its own list. */
    LazyLoader {
        active: appMenu.shown

        MenuWindow {
            menu: appMenu
        }
    }

    LazyLoader {
        active: powerMenu.shown

        MenuWindow {
            menu: powerMenu
        }
    }

    LazyLoader {
        active: repoMenu.shown

        MenuWindow {
            menu: repoMenu
        }
    }

    LazyLoader {
        active: bookmarkMenu.shown

        MenuWindow {
            menu: bookmarkMenu
        }
    }

    Variants {
        model: Quickshell.screens

        DwmPanel {
            required property var modelData

            screen: modelData
            state: dwmState
            clock: clock
            audioModel: audioModel
            batteryModel: batteryModel
            bluetoothModel: bluetoothModel
            networkModel: networkModel
            updateModel: updateModel
            primaryPanel: modelData === Quickshell.screens[0]
            onPowerMenuRequested: root.toggleMenu(powerMenu)
        }
    }

    IpcHandler {
        target: "apps"

        function open(): void {
            root.openMenu(appMenu);
        }

        function close(): void {
            appMenu.close();
        }

        function toggle(): void {
            root.toggleMenu(appMenu);
        }
    }

    IpcHandler {
        target: "power"

        function open(): void {
            root.openMenu(powerMenu);
        }

        function close(): void {
            powerMenu.close();
        }

        function toggle(): void {
            root.toggleMenu(powerMenu);
        }
    }

    IpcHandler {
        target: "repos"

        function open(): void {
            root.openMenu(repoMenu);
        }

        function close(): void {
            repoMenu.close();
        }

        function toggle(): void {
            root.toggleMenu(repoMenu);
        }
    }

    IpcHandler {
        target: "bookmarks"

        function open(): void {
            root.openMenu(bookmarkMenu);
        }

        function close(): void {
            bookmarkMenu.close();
        }

        function toggle(): void {
            root.toggleMenu(bookmarkMenu);
        }
    }
}
