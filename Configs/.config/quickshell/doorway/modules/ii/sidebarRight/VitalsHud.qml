import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * Boardroom vitals band — the ONE zone where the ENCOM data-flow shader lives.
 * The rest of the sidebar is flat ink; motion is an instrument here, not
 * wallpaper. Connection icon + uptime on top, neon meters (CPU, MEM, NET)
 * beneath, all over the shader with a scrim so the readout stays legible.
 * The shader's traces surge with real net/CPU load and its clock only runs
 * while the sidebar is open (VCS APU budget).
 */
Item {
    id: root
    implicitHeight: layout.implicitHeight + 26

    // Recessed well the shader sits in.
    Rectangle {
        anchors.fill: parent
        color: DoorwayPalette.hudWell
    }

    EncomBackground {
        anchors.fill: parent
        anchors.margins: 1
        radius: 0
        borderWidth: 0
        active: GlobalStates.sidebarRightOpen
        activity: Math.max(ResourceUsage.netDownPercentage, ResourceUsage.cpuUsage)
    }

    // Scrim — heavier at the bottom where the meter values sit.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(DoorwayPalette.hudWell.r, DoorwayPalette.hudWell.g, DoorwayPalette.hudWell.b, 0.35) }
            GradientStop { position: 1.0; color: Qt.rgba(DoorwayPalette.hudWell.r, DoorwayPalette.hudWell.g, DoorwayPalette.hudWell.b, 0.72) }
        }
    }

    // Hairline frame + bright corner brackets over everything.
    HudPanel {
        anchors.fill: parent
        color: "transparent"
        radius: 0
        showTicks: true
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 13
        spacing: 10

        // --- identity line: network name (left) · uptime (right) ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                text: Network.ethernet ? "lan" : "wifi"
                iconSize: 16
                color: DoorwayPalette.skyHint
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: "UP " + DateTime.uptime
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                font.letterSpacing: 1
                color: DoorwayPalette.powerGold
            }
        }

        // --- meter row ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

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
                accent: DoorwayPalette.skyHint
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
            font.letterSpacing: 1
            color: DoorwayPalette.hudLabel
        }
        StyledText {
            text: value
            elide: Text.ElideRight
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.family: Appearance.font.family.numbers
            color: DoorwayPalette.hudText
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 2
            color: Qt.rgba(1, 1, 1, 0.10)   // track
            Rectangle {
                height: parent.height
                width: parent.width * Math.max(0, Math.min(1, fraction))
                color: accent
                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
