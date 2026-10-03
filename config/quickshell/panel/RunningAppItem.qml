pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core

Rectangle {
    id: root

    required property var app
    required property bool active
    signal focusRequested(string windowId)

    Layout.preferredWidth: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    radius: Theme.pillRadius
    color: appMouse.containsMouse ? Theme.controlHoverFill : Theme.transparent

    Behavior on color {
        ColorAnimation { duration: Theme.animationNormal }
    }

    IconImage {
        id: appIcon

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.trayIconSize
        height: Theme.trayIconSize
        source: Icons.launcherIcon(root.app.appClass)
        opacity: root.active || appMouse.containsMouse ? 1.0 : 0.55
        mipmap: true

        layer.enabled: true
        /* Qt sizes a layer texture in logical pixels, so without multiplying by
         * the device pixel ratio a HiDPI screen renders the icon at 17px and
         * stretches it. Ceil, because a texture is a whole number of pixels. */
        layer.smooth: true
        layer.textureSize: Qt.size(
            Math.ceil(appIcon.width * Screen.devicePixelRatio),
            Math.ceil(appIcon.height * Screen.devicePixelRatio))
        layer.effect: MultiEffect {
            saturation: appMouse.containsMouse ? 0.0 : -1.0

            Behavior on saturation {
                NumberAnimation { duration: Theme.animationNormal }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animationNormal }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.underlineHeight
        width: Theme.underlineWidth
        height: Theme.underlineHeight
        radius: height / 2
        color: Theme.accent
        visible: root.active
    }

    MouseArea {
        id: appMouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.focusRequested(root.app.windowId)
    }
}
