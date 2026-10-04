import QtQuick
import Quickshell.Widgets
import qs.core

/* One row of a menu list: a selection mark, an icon, the label with the typed
 * run picked out of it, and a dimmed detail on the right. */
Rectangle {
    id: root

    required property string label
    required property string detail
    /* A glyph from the icon font, or an image path. A row sets one or the
     * other; the apps menu is the only caller with real icons to draw. */
    required property string icon
    property string iconSource: ""
    required property bool selected
    required property int detailElide
    /* What the user has typed, so the part of the label that answered it can be
     * picked out. Without this the list gives no feedback that the filter is
     * matching anything in particular. */
    required property string query

    signal activated()

    readonly property int contentLeft: Theme.menuPadding + Theme.menuSpacing
    readonly property int labelLeft: root.contentLeft + Theme.menuIconSize + Theme.menuPadding

    function escapeMarkup(value) {
        return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    /* StyledText rather than a row of three Text items, so the label still
     * elides as one string when it is too long for the row. */
    readonly property string labelMarkup: {
        const needle = root.query.trim();
        const escaped = root.escapeMarkup(root.label);

        if (needle.length === 0) {
            return escaped;
        }

        const at = root.label.toLowerCase().indexOf(needle.toLowerCase());

        if (at === -1) {
            return escaped;
        }

        return root.escapeMarkup(root.label.substring(0, at))
            + "<font color=\"" + Theme.accent + "\">"
            + root.escapeMarkup(root.label.substring(at, at + needle.length))
            + "</font>"
            + root.escapeMarkup(root.label.substring(at + needle.length));
    }

    implicitHeight: Theme.menuRowHeight
    radius: Theme.menuRowRadius
    color: root.selected ? Theme.controlSelectedFill
        : rowMouse.containsMouse ? Theme.controlHoverFill : Theme.transparent

    Behavior on color {
        ColorAnimation { duration: Theme.animationNormal }
    }

    Rectangle {
        id: rowMark

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.menuMarkWidth
        height: Math.round(parent.height * Theme.menuMarkFraction)
        radius: width / 2
        color: Theme.accent
        opacity: root.selected ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animationNormal }
        }
    }

    IconText {
        id: rowIcon

        anchors.left: parent.left
        anchors.leftMargin: root.contentLeft
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.menuIconSize
        visible: root.iconSource.length === 0
        text: root.icon
        color: root.selected ? Theme.accent : Theme.text
    }

    IconImage {
        anchors.left: parent.left
        anchors.leftMargin: root.contentLeft
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.menuIconSize
        height: Theme.menuIconSize
        visible: root.iconSource.length > 0
        source: root.iconSource
        /* Dimmed until the row is the one being chosen, so the list reads as a
         * list of names rather than a wall of colour. */
        opacity: root.selected || rowMouse.containsMouse ? 1.0 : 0.65
        mipmap: true

        Behavior on opacity {
            NumberAnimation { duration: Theme.animationNormal }
        }
    }

    ProseText {
        id: rowLabel

        anchors.left: parent.left
        anchors.leftMargin: root.labelLeft
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, root.width - root.labelLeft
            - Theme.menuPadding * 2 - rowDetail.width)
        textFormat: Text.StyledText
        text: root.labelMarkup
        color: root.selected ? Theme.textStrong : Theme.text
        elide: Text.ElideRight
    }

    ProseText {
        id: rowDetail

        anchors.right: parent.right
        anchors.rightMargin: Theme.menuPadding
        anchors.verticalCenter: parent.verticalCenter
        /* Capped at half the row so a long path cannot crowd out the label,
         * which is the part being chosen between. */
        width: Math.min(implicitWidth, root.width / 2)
        horizontalAlignment: Text.AlignRight
        text: root.detail
        color: root.selected ? Theme.text : Theme.textMuted
        font.pixelSize: Theme.tinyFontSize
        elide: root.detailElide
    }

    MouseArea {
        id: rowMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
