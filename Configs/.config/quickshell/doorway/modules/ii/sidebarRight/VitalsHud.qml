import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * Boardroom vitals strip — the live "readout" header of the ENCOM sidebar.
 * A HudPanel carrying the network identity + uptime on top and a row of neon
 * meters (CPU, MEM, NET ▼down / ▲up) beneath. Reuses ResourceUsage's sampling
 * (same data the bar gauges read) so the numbers stay consistent shell-wide.
 */
HudPanel {
    id: root
    implicitHeight: layout.implicitHeight + 20

    readonly property string netName: Network.ethernet ? Translation.tr("Ethernet")
        : (Network.networkName && Network.networkName.length > 0 ? Network.networkName
        : Translation.tr("Offline"))

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // --- identity line: network name (left) · uptime (right) ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                text: Network.ethernet ? "lan" : "wifi"
                iconSize: 18
                color: DoorwayPalette.skyHint
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.netName
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: Appearance.font.family.monospace
                color: DoorwayPalette.skyHint
            }
            StyledText {
                text: "UP " + DateTime.uptime
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: Appearance.font.family.monospace
                color: DoorwayPalette.powerGold
            }
        }

        // --- meter row ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            StatMeter {
                Layout.fillWidth: true
                label: "CPU"
                value: Math.round(ResourceUsage.cpuUsage * 100) + "%"
                fraction: ResourceUsage.cpuUsage
                accent: DoorwayPalette.skyHint
            }
            StatMeter {
                Layout.fillWidth: true
                label: "MEM"
                value: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                fraction: ResourceUsage.memoryUsedPercentage
                accent: DoorwayPalette.skyHint
            }
            StatMeter {
                Layout.fillWidth: true
                label: "NET ▼"
                value: ResourceUsage.bytesPerSecString(ResourceUsage.netDownBytesPerSec)
                fraction: ResourceUsage.netDownPercentage
                accent: DoorwayPalette.heroBlue
            }
            StatMeter {
                Layout.fillWidth: true
                label: "NET ▲"
                value: ResourceUsage.bytesPerSecString(ResourceUsage.netUpBytesPerSec)
                fraction: ResourceUsage.netUpPercentage
                accent: DoorwayPalette.powerGold
            }
        }
    }

    // one labelled cell: label, value, thin neon meter bar
    component StatMeter: ColumnLayout {
        property string label: ""
        property string value: ""
        property real fraction: 0
        property color accent: DoorwayPalette.skyHint
        spacing: 3

        StyledText {
            text: label
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.family: Appearance.font.family.monospace
            color: Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b, 0.6)
        }
        StyledText {
            text: value
            elide: Text.ElideRight
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.family: Appearance.font.family.numbers
            color: accent
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 3
            radius: 1.5
            color: Qt.rgba(1, 1, 1, 0.08)   // track
            Rectangle {
                height: parent.height
                radius: parent.radius
                width: parent.width * Math.max(0, Math.min(1, fraction))
                color: accent
                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
