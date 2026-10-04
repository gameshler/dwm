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
    readonly property int stride: Theme.menuRowHeight + Theme.menuSpacing

    title: "dwm-menu"
    color: Theme.menuFill
    visible: root.menu.shown

    readonly property int wantedHeight: Theme.menuPadding * 2
        + Theme.menuFieldHeight
        + Theme.menuSpacing
        + Theme.separatorWidth
        + Math.max(root.stride, root.listRows * root.stride)
        + (root.menu.message.length > 0 ? root.stride : 0)

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
        radius: Theme.pillRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.menuPadding
            spacing: Theme.menuSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.menuFieldHeight
                spacing: Theme.menuPadding

                UiText {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.menu.title
                    color: Theme.accent
                    font.bold: true
                }

                TextInput {
                    id: field

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    color: Theme.textStrong
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelFontSize
                    selectByMouse: true
                    selectionColor: Theme.surfaceActive
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
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.separatorWidth
                color: Theme.border
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
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
                    selected: index === root.menu.selectedIndex
                    onActivated: root.menu.activateIndex(index)
                }
            }

            UiText {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.menuRowHeight
                visible: root.menu.message.length > 0
                text: root.menu.message
                color: Theme.danger
                font.pixelSize: Theme.smallFontSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
