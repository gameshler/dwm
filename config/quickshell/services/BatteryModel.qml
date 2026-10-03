import Quickshell
import Quickshell.Services.UPower

Scope {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: root.device !== null && root.device.ready && root.device.isLaptopBattery
    /* UPowerDevice.percentage is a 0..1 fraction despite the name. */
    readonly property int percent: root.available ? Math.round(root.device.percentage * 100) : 0
    /* UPower.onBattery can go stale on some hardware; the device state does not. */
    readonly property bool charging: root.available && root.device.state === UPowerDeviceState.Charging
    readonly property string statusText: !root.available ? ""
        : root.percent + "% - " + (root.charging ? "charging" : "discharging")

    readonly property string icon: {
        if (!root.available) return "";
        if (root.charging) return "󰂄";
        if (root.percent >= 90) return "󰁹";
        if (root.percent >= 80) return "󰂂";
        if (root.percent >= 70) return "󰂁";
        if (root.percent >= 60) return "󰂀";
        if (root.percent >= 50) return "󰁿";
        if (root.percent >= 40) return "󰁾";
        if (root.percent >= 30) return "󰁽";
        if (root.percent >= 20) return "󰁼";
        if (root.percent >= 10) return "󰁻";
        return "󰂎";
    }
}
