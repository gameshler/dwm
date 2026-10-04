pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

/* A FloatingWindow, not a PanelWindow or a PopupWindow, and the reason is
 * keyboard focus. Quickshell gives both of those _NET_WM_WINDOW_TYPE_DOCK on
 * X11; dwm does not manage a dock window, so it never focuses one, and a menu
 * that cannot take a keystroke is no use. Measured under Xvfb: typing into a
 * dock-type menu produced nothing until XSetInputFocus was forced onto it by
 * hand, while a normal window was focused by dwm the moment it mapped and took
 * input with no help at all.
 *
 * config.h carries the matching rules[] entry that floats it. The rule matches
 * on title, because Quickshell sets no WM_CLASS on any of its windows. */
FloatingWindow {
    id: root

    required property var menu

    readonly property int listRows: Math.min(root.menu.rows.length, Theme.menuMaxRows)
    readonly property bool hasMessage: root.menu.message.length > 0

    /* An empty list still gets one row of height, for the "no matches" line that
     * takes its place. */
    readonly property int listHeight: root.listRows > 0
        ? root.listRows * Theme.menuRowHeight + (root.listRows - 1) * Theme.menuSpacing
        : Theme.menuRowHeight

    title: "dwm-menu"
    color: Theme.menuFill
    visible: root.menu.shown

    /* Every item the column always shows, plus the gaps between them. The
     * message row is the only optional one, so it adds a gap of its own. */
    readonly property int wantedHeight: Theme.menuPadding * 2
        + Theme.menuFieldHeight
        + root.listHeight
        + Theme.separatorWidth
        + Theme.menuFooterHeight
        + Theme.menuGap * 3
        + (root.hasMessage ? Theme.menuRowHeight + Theme.menuGap : 0)

    /* Read once, when dwm manages the window. dwm fixes a floating client's
     * geometry at that point and ignores a later resize request, which is why
     * shell.qml destroys this window on close rather than reusing it, and why a
     * menu whose list loads asynchronously must not be shown until it has. The
     * list scrolls rather than the window growing once it is open. */
    implicitWidth: Theme.menuWidth
    implicitHeight: root.wantedHeight

    /* The window is focused by dwm, but the field inside it has to be told to
     * take that focus, or the keys land on the window and go nowhere. */
    onVisibleChanged: if (root.visible) {
        Qt.callLater(function () {
            field.forceActiveFocus();
        });
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.menuFill
        border.color: Theme.menuBorder
        border.width: Theme.pillBorderWidth
        radius: Theme.menuRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.menuPadding
            spacing: Theme.menuGap

            /* The one surface in the menu that reads as raised. Everything else
             * is the same near-black as the window, so the eye starts here. */
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.menuFieldHeight
                radius: Theme.menuRowRadius
                color: Theme.menuFieldFill
                border.color: field.activeFocus ? Theme.accentSecondary : Theme.menuFieldBorder
                border.width: Theme.pillBorderWidth

                Behavior on border.color {
                    ColorAnimation { duration: Theme.animationNormal }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.menuPadding
                    anchors.rightMargin: Theme.menuPadding
                    spacing: Theme.menuPadding

                    IconText {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: Theme.menuIconSize
                        text: root.menu.menuIcon
                        color: Theme.accent
                    }

                    TextInput {
                        id: field

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: Theme.textStrong
                        font.family: Theme.uiFontFamily
                        font.pixelSize: Theme.panelFontSize
                        selectByMouse: true
                        selectionColor: Theme.accentSecondary
                        selectedTextColor: Theme.textStrong
                        focus: true
                        text: root.menu.query
                        onTextChanged: root.menu.query = text

                        ProseText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: field.text.length === 0
                            text: root.menu.placeholder
                            color: Theme.textMuted
                        }

                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_Escape) {
                                root.menu.close();
                            } else if (event.key === Qt.Key_Down
                                    || (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier))) {
                                root.menu.move(1);
                            } else if (event.key === Qt.Key_Up
                                    || (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier))) {
                                root.menu.move(-1);
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.menu.activateSelected();
                            } else {
                                return;
                            }

                            event.accepted = true;
                        }
                    }

                    /* Only while filtering. At rest the count of everything
                     * installed is noise; once something has been typed it is
                     * the answer to how well it narrowed. */
                    ProseText {
                        Layout.alignment: Qt.AlignVCenter
                        visible: root.menu.query.trim().length > 0
                        text: root.menu.rows.length + " / " + root.menu.entries.length
                        color: Theme.textMuted
                        font.pixelSize: Theme.tinyFontSize
                    }
                }
            }

            /* The list, its empty state and its scroll indicator are one layout
             * child, so the column's spacing does not change with them. */
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: list

                    anchors.fill: parent
                    clip: true
                    spacing: Theme.menuSpacing
                    model: root.menu.rows
                    currentIndex: root.menu.selectedIndex
                    /* Keeps the selection on screen once the list is longer than
                     * menuMaxRows and the only way to reach the rest is the keys. */
                    highlightMoveDuration: 0
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: height
                    highlightRangeMode: ListView.ApplyRange
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: MenuEntryRow {
                        required property var modelData
                        required property int index

                        width: list.width
                        label: modelData.label
                        detail: modelData.detail || ""
                        icon: modelData.icon || ""
                        iconSource: modelData.iconSource || ""
                        query: root.menu.query
                        detailElide: root.menu.detailElide
                        selected: index === root.menu.selectedIndex
                        onActivated: root.menu.activateIndex(index)
                    }
                }

                ProseText {
                    anchors.centerIn: parent
                    visible: root.menu.rows.length === 0
                    text: root.menu.emptyText
                    color: Theme.textMuted
                }

                /* Shown only when the list is taller than the window, which is
                 * the only time the user needs to know there is more. */
                Rectangle {
                    anchors.right: parent.right
                    width: Theme.menuScrollWidth
                    radius: width / 2
                    color: Theme.borderStrong
                    visible: list.contentHeight > list.height && list.contentHeight > 0
                    height: Math.max(Theme.menuRowHeight / 2,
                        parent.height * (list.height / list.contentHeight))
                    y: list.contentHeight > list.height
                        ? (parent.height - height) * (list.contentY
                            / (list.contentHeight - list.height))
                        : 0
                }
            }

            UiText {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.menuRowHeight
                visible: root.hasMessage
                text: root.menu.message
                color: Theme.danger
                font.pixelSize: Theme.smallFontSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.separatorWidth
                color: Theme.border
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.menuFooterHeight
                spacing: Theme.menuPadding

                MenuHint {
                    key: "↑ ↓"
                    action: "move"
                }

                MenuHint {
                    key: "⏎"
                    action: "open"
                }

                MenuHint {
                    key: "esc"
                    action: "close"
                }

                Item {
                    Layout.fillWidth: true
                }

                /* The menu's own name, last: it answers "which menu is this"
                 * without competing with the field for attention. */
                ProseText {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.menu.title
                    color: Theme.accent
                    font.pixelSize: Theme.tinyFontSize
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: Theme.clockLetterSpacing
                }
            }
        }
    }
}
