pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

// qmllint disable uncreatable-type
PanelWindow {
    id: root

    required property var state
    required property var clock
    required property var audioModel
    required property var batteryModel
    required property var bluetoothModel
    required property var networkModel
    required property var updateModel
    required property bool primaryPanel

    signal powerMenuRequested()

    implicitHeight: Theme.panelHeight
    color: Theme.barBackground
    exclusiveZone: Theme.panelHeight

    /* The same minimum for both side groups, which is the only way the centre
     * group stays centred: a RowLayout hands each fillWidth item its minimum
     * before splitting the surplus, so a minimum on one side alone drags the
     * clock off centre. Floored at the tag row, the one group that cannot
     * compress or be dropped. */
    readonly property int sideGroupMinimum: {
        const half = Math.floor((width - clockLabel.implicitWidth) / 2)
            - Theme.panelGroupGap;
        return Math.max(tagsRow.implicitWidth, Math.min(rightRow.implicitWidth, half));
    }

    /* Measured off the font, not off the row that draws it: a hidden RowLayout
     * can stop reporting an implicit width, so a visibility rule reading it
     * would decide from its own consequence and oscillate. */
    readonly property int statusNaturalWidth: {
        const count = root.state.statusSegments.length;
        if (count === 0) {
            return 0;
        }
        return Math.ceil(statusMetrics.advanceWidth)
            + (count - 1) * Theme.panelGroupGap
            + Theme.panelGap + Theme.separatorWidth;
    }
    aboveWindows: root.state.fullscreenMonitorIndexes.indexOf(
        root.state.screenIndex(root.screen)) === -1

    anchors {
        top: true
        left: true
        right: true
    }

    /* Must stay in step with the delegate in the status row below. */
    TextMetrics {
        id: statusMetrics

        font.family: Theme.fontFamily
        font.pixelSize: Theme.smallFontSize
        text: root.state.statusSegments.join("")
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Theme.barEdgeWidth
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.panelSideMargin
        anchors.rightMargin: Theme.panelSideMargin
        spacing: Theme.panelGroupGap

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: root.sideGroupMinimum

            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, parent.width)
                height: parent.height
                spacing: Theme.panelGroupGap

                RowLayout {
                    id: tagsRow

                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Repeater {
                        model: root.state.workspaceIndexes(root.screen)

                        delegate: WorkspaceButton {
                            required property int modelData

                            label: root.state.workspaceNames[modelData]
                            selected: modelData === root.state.currentWorkspaceForScreen(root.screen)
                            occupied: root.state.workspaceOccupied(modelData)
                            onClicked: root.state.switchWorkspaceForScreen(root.screen, modelData)
                        }
                    }
                }

                ProseText {
                    id: activeTitle

                    /* fillWidth with no minimum is what stops a long title
                     * overprinting the clock; it is the one thing in this row
                     * that gives when the row is squeezed. */
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: Math.max(Theme.titleMinWidth,
                        Math.round(root.width * Theme.titleWidthFraction))
                    Layout.alignment: Qt.AlignVCenter
                    text: root.state.activeWindowTitle
                    color: Theme.text
                    elide: Text.ElideRight
                }
            }
        }

        UiText {
            id: clockLabel

            Layout.alignment: Qt.AlignVCenter
            text: root.clock.panelText
            color: Theme.textStrong
            font.bold: true
            font.letterSpacing: Theme.clockLetterSpacing
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: root.sideGroupMinimum

            RowLayout {
                id: rightRow

                anchors.fill: parent
                spacing: Theme.panelGap

                /* The status line is anchored inside this rather than being a
                 * layout child, which keeps rightRow's implicit width - and so
                 * the group minimums - independent of whether the status is
                 * drawn. As a layout child the measurement feeds back on itself. */
                Item {
                    id: statusSlack

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0

                    RowLayout {
                        id: statusGroup

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: implicitWidth
                        spacing: Theme.panelGap
                        visible: root.statusNaturalWidth > 0
                            && statusSlack.width
                                >= root.statusNaturalWidth + Theme.panelGroupGap

                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: Theme.panelGroupGap

                            Repeater {
                                model: root.state.statusSegments

                                delegate: UiText {
                                    required property string modelData

                                    Layout.alignment: Qt.AlignVCenter
                                    text: modelData
                                    color: Theme.text
                                    font.pixelSize: Theme.smallFontSize
                                }
                            }
                        }

                        PanelSeparator {}
                    }
                }

                PanelPill {
                    id: updatePill

                    visible: root.updateModel.available && root.updateModel.count > 0
                    Layout.preferredWidth: Math.ceil(updateRow.implicitWidth)
                        + Theme.compactWidgetHorizontalPadding * 2
                    Layout.preferredHeight: Theme.compactWidgetSize
                    Layout.alignment: Qt.AlignVCenter
                    hovered: updateMouse.containsMouse

                    RowLayout {
                        id: updateRow

                        anchors.centerIn: parent
                        spacing: Theme.compactSpacing

                        IconText {
                            text: root.updateModel.icon
                            color: Theme.warning
                        }

                        UiText {
                            text: root.updateModel.count
                            color: Theme.warning
                        }
                    }

                    MouseArea {
                        id: updateMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.updateModel.openUpdater()
                    }
                }

                RunningAppsArea {
                    id: runningApps

                    Layout.alignment: Qt.AlignVCenter
                    desktopState: root.state
                    /* Measured off the bar, not the space left over: that would
                     * be circular, since the dock is part of what decides it. */
                    maximumWidth: Math.max(Theme.dockMinimumWidth,
                        Math.round(root.width * Theme.dockWidthFraction))
                }

                PanelSeparator {
                    visible: root.state.runningApps.length > 0
                }

                /* One tray host only; a second would fight for the
                 * StatusNotifierWatcher name. */
                Loader {
                    Layout.alignment: Qt.AlignVCenter
                    active: root.primaryPanel
                    sourceComponent: TrayArea {}
                }

                PanelPill {
                    id: batteryPill

                    visible: root.batteryModel.available
                    Layout.preferredWidth: Math.ceil(batteryRow.implicitWidth)
                        + Theme.compactWidgetHorizontalPadding * 2
                    Layout.preferredHeight: Theme.compactWidgetSize
                    Layout.alignment: Qt.AlignVCenter
                    hovered: batteryMouse.containsMouse

                    readonly property string tint: root.batteryModel.charging ? Theme.success
                        : root.batteryModel.percent <= 15 ? Theme.danger
                        : Theme.textStrong

                    RowLayout {
                        id: batteryRow

                        anchors.centerIn: parent
                        spacing: Theme.compactSpacing

                        IconText {
                            text: root.batteryModel.icon
                            color: batteryPill.tint
                        }

                        UiText {
                            text: root.batteryModel.percent + "%"
                            color: batteryPill.tint
                        }
                    }

                    MouseArea {
                        id: batteryMouse

                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }

                PanelPill {
                    visible: root.bluetoothModel.available
                    Layout.preferredWidth: Theme.compactWidgetSize + Theme.compactWidgetHorizontalPadding
                    Layout.preferredHeight: Theme.compactWidgetSize
                    Layout.alignment: Qt.AlignVCenter
                    hovered: bluetoothMouse.containsMouse

                    IconText {
                        anchors.centerIn: parent
                        text: root.bluetoothModel.icon
                        color: Theme.textStrong
                    }

                    MouseArea {
                        id: bluetoothMouse

                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }

                PanelPill {
                    visible: root.networkModel.available
                    Layout.preferredWidth: Theme.compactWidgetSize + Theme.compactWidgetHorizontalPadding
                    Layout.preferredHeight: Theme.compactWidgetSize
                    Layout.alignment: Qt.AlignVCenter
                    hovered: networkMouse.containsMouse

                    IconText {
                        anchors.centerIn: parent
                        text: root.networkModel.icon
                        color: root.networkModel.connected ? Theme.textStrong : Theme.text
                    }

                    MouseArea {
                        id: networkMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.networkModel.openEditor()
                    }
                }

                PanelPill {
                    visible: root.audioModel.available
                    Layout.preferredWidth: Math.ceil(volumeRow.implicitWidth)
                        + Theme.compactWidgetHorizontalPadding * 2
                    Layout.preferredHeight: Theme.compactWidgetSize
                    Layout.alignment: Qt.AlignVCenter
                    hovered: volumeMouse.containsMouse

                    RowLayout {
                        id: volumeRow

                        anchors.centerIn: parent
                        spacing: Theme.compactSpacing

                        IconText {
                            text: root.audioModel.muted ? "󰝟" : "󰕾"
                            color: root.audioModel.muted ? Theme.text : Theme.textStrong
                        }

                        UiText {
                            text: root.audioModel.volumePercent + "%"
                            color: root.audioModel.muted ? Theme.text : Theme.textStrong
                        }
                    }

                    MouseArea {
                        id: volumeMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.MiddleButton) {
                                root.audioModel.toggleMute();
                            } else {
                                root.audioModel.openMixer();
                            }
                        }
                        onWheel: function(wheel) {
                            if (wheel.angleDelta.y > 0) {
                                root.audioModel.volumeUp();
                            } else if (wheel.angleDelta.y < 0) {
                                root.audioModel.volumeDown();
                            }
                            wheel.accepted = true;
                        }
                    }
                }

                /* Only when an indicator actually rendered: a desktop machine has
                 * no battery and often no bluetooth. */
                PanelSeparator {
                    visible: root.batteryModel.available || root.bluetoothModel.available
                        || root.networkModel.available || root.audioModel.available
                }

                PanelPill {
                    Layout.preferredWidth: Theme.compactWidgetSize + Theme.compactWidgetHorizontalPadding
                    Layout.preferredHeight: Theme.compactWidgetSize
                    Layout.alignment: Qt.AlignVCenter
                    hovered: powerMouse.containsMouse

                    IconText {
                        anchors.centerIn: parent
                        text: "󰐥"
                        color: powerMouse.containsMouse ? Theme.danger : Theme.textStrong

                        Behavior on color {
                            ColorAnimation { duration: Theme.animationNormal }
                        }
                    }

                    MouseArea {
                        id: powerMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.powerMenuRequested()
                    }
                }
            }
        }
    }

    PanelTooltip {
        visible: updatePill.visible && updateMouse.containsMouse
        anchorWindow: root
        anchorItem: updatePill
        label: root.updateModel.statusText
        anchorY: Theme.panelHeight
        rightAligned: true
    }

    PanelTooltip {
        visible: root.batteryModel.available && batteryMouse.containsMouse
        anchorWindow: root
        anchorItem: batteryPill
        label: root.batteryModel.statusText
        anchorY: Theme.panelHeight
        rightAligned: true
    }

    PanelTooltip {
        visible: bluetoothMouse.containsMouse
        anchorWindow: root
        anchorItem: bluetoothMouse
        label: root.bluetoothModel.statusText
        anchorY: Theme.panelHeight
        rightAligned: true
    }

    PanelTooltip {
        visible: networkMouse.containsMouse
        anchorWindow: root
        anchorItem: networkMouse
        label: root.networkModel.statusText
        anchorY: Theme.panelHeight
        rightAligned: true
    }

    PanelTooltip {
        visible: volumeMouse.containsMouse
        anchorWindow: root
        anchorItem: volumeMouse
        label: root.audioModel.statusText
        anchorY: Theme.panelHeight
        rightAligned: true
    }

    PanelTooltip {
        visible: powerMouse.containsMouse
        anchorWindow: root
        anchorItem: powerMouse
        label: "Power menu"
        anchorY: Theme.panelHeight
        rightAligned: true
    }
}
