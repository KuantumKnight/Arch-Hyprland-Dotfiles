import QtQuick
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Column {
    id: root

    required property color colour
    readonly property real level: Math.max(0, Math.min(1, UPower.displayDevice.percentage))
    readonly property color lowBatteryColour: UPower.displayDevice.state === UPowerDeviceState.Charging
                                              ? Colours.palette.m3success
                                              : level < 0.1 ? Colours.palette.m3error : "#e5c07b"
    readonly property bool lowBattery: UPower.displayDevice.isLaptopBattery && level < 0.2

    spacing: 1
    width: Math.max(icon.implicitWidth, percentage.visible ? percentage.implicitWidth : 0)

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: parent.horizontalCenter
        animate: true
        text: {
            if (!UPower.displayDevice.isLaptopBattery) {
                if (PowerProfiles.profile === PowerProfile.PowerSaver)
                    return "energy_savings_leaf";
                if (PowerProfiles.profile === PowerProfile.Performance)
                    return "rocket_launch";
                return "balance";
            }
            return Icons.getBatteryIcon(root.level, [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state));
        }
        color: root.lowBattery ? root.lowBatteryColour : root.colour
        fill: 1
    }

    StyledText {
        id: percentage

        anchors.horizontalCenter: parent.horizontalCenter
        visible: UPower.displayDevice.isLaptopBattery
        text: Math.round(root.level * 100) + "%"
        font.family: Tokens.font.label.small.family
        font.pixelSize: 11
        font.weight: Font.Medium
        color: root.lowBattery ? root.lowBatteryColour : Colours.palette.m3onSurfaceVariant
    }
}
