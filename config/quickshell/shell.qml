//@ pragma UseQApplication

pragma ComponentBehavior: Bound

import Quickshell
import qs.core
import qs.panel
import qs.services
import qs.state

ShellRoot {
    id: root

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
        }
    }
}
