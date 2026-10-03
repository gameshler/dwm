import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    required property string label
    required property bool selected
    required property bool occupied

    signal clicked()

    Layout.preferredWidth: Theme.workspaceButtonSize
    Layout.preferredHeight: Theme.pillHeight
    radius: Theme.smallRadius
    color: workspaceMouse.containsMouse ? Theme.controlHoverFill : Theme.transparent

    Behavior on color {
        ColorAnimation { duration: Theme.animationNormal }
    }

    UiText {
        id: tagLabel

        anchors.horizontalCenter: parent.horizontalCenter
        /* Dead centre, like every other baseline in the bar. The mark hangs off
         * the bottom of the cell rather than lifting the numeral. */
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.selected ? Theme.accent
            : workspaceMouse.containsMouse ? Theme.controlHoverText
            : root.occupied ? Theme.text : Theme.textMuted
        font.bold: root.selected
    }

    Rectangle {
        id: indicator

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.underlineHeight
        width: root.selected ? Theme.underlineWidth
            : root.occupied ? Theme.occupiedMarkWidth : 0
        height: Theme.underlineHeight
        radius: height / 2
        color: root.selected ? Theme.accent : Theme.text
        visible: root.selected || root.occupied

        Behavior on width {
            NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: workspaceMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
