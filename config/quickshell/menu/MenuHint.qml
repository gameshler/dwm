import QtQuick
import QtQuick.Layouts
import qs.core

/* One keybinding in a menu's footer: the key on a chip, what it does beside it.
 * These are in the footer rather than in the README because a menu opened from
 * a keybinding is the one surface where nobody is reading documentation. */
RowLayout {
    id: root

    required property string key
    required property string action

    spacing: Theme.menuSpacing

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: keyLabel.implicitWidth + Theme.menuSpacing * 2
        implicitHeight: Theme.menuFooterHeight
        radius: Theme.smallRadius / 2
        color: Theme.menuFieldFill
        border.color: Theme.menuFieldBorder
        border.width: Theme.pillBorderWidth

        ProseText {
            id: keyLabel

            anchors.centerIn: parent
            text: root.key
            color: Theme.text
            font.pixelSize: Theme.tinyFontSize
        }
    }

    ProseText {
        Layout.alignment: Qt.AlignVCenter
        text: root.action
        color: Theme.textMuted
        font.pixelSize: Theme.tinyFontSize
    }
}
