import QtQuick
import qs.core

Rectangle {
    id: root

    required property string label
    required property string detail
    required property string icon
    required property bool selected

    signal activated()

    implicitHeight: Theme.menuRowHeight
    radius: Theme.smallRadius
    color: root.selected ? Theme.controlSelectedFill
        : rowMouse.containsMouse ? Theme.controlHoverFill : Theme.transparent

    Behavior on color {
        ColorAnimation { duration: Theme.animationNormal }
    }

    IconText {
        id: rowIcon

        anchors.left: parent.left
        anchors.leftMargin: Theme.menuPadding
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.menuIconSize
        text: root.icon
        color: root.selected ? Theme.accent : Theme.text
    }

    ProseText {
        id: rowLabel

        anchors.left: rowIcon.right
        anchors.leftMargin: Theme.menuPadding
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, root.width - rowIcon.width
            - Theme.menuPadding * 3 - rowDetail.width)
        text: root.label
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
        color: Theme.textMuted
        font.pixelSize: Theme.tinyFontSize
        elide: Text.ElideLeft
    }

    MouseArea {
        id: rowMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
