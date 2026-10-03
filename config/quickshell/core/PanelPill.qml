import QtQuick
import qs.core

Rectangle {
    property bool active: false
    property bool hovered: false

    implicitHeight: Theme.pillHeight
    color: active ? Theme.controlSelectedFill
        : hovered ? Theme.controlHoverFill : Theme.transparent
    radius: Theme.pillRadius

    Behavior on color {
        ColorAnimation { duration: Theme.animationNormal }
    }
}
