import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * "By the Numbers" — system vitals as editorial gauges. Uses ResourceUsage (CPU/RAM/swap),
 * a small `df` process for disk, and DateTime.uptime / SystemInfo for the footer line.
 * (No updates count: NixOS has no `checkupdates` equivalent, so it is deliberately omitted.)
 */
Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    property real diskFrac: 0
    property string diskLabel: "--"

    Process {
        id: dfProc
        command: ["df", "-P", "/"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 2) {
                    const c = lines[lines.length - 1].trim().split(/\s+/);
                    const size = parseInt(c[1]), used = parseInt(c[2]); // 1024-blocks
                    if (size > 0) {
                        root.diskFrac = used / size;
                        root.diskLabel = (used / 1048576).toFixed(0) + " / " + (size / 1048576).toFixed(0) + " GB";
                    }
                }
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: dfProc.running = true }
    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() { if (GlobalStates.sidebarLeftOpen) dfProc.running = true; }
    }

    readonly property var gauges: [
        { label: qsTr("Processor"), frac: ResourceUsage.cpuUsage,
          value: Math.round(ResourceUsage.cpuUsage * 100) + "%" },
        { label: qsTr("Memory"), frac: ResourceUsage.memoryUsedPercentage,
          value: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed) + " / " + ResourceUsage.maxAvailableMemoryString },
        { label: qsTr("Swap"), frac: ResourceUsage.swapUsedPercentage,
          value: ResourceUsage.swapTotal > 1 ? ResourceUsage.kbToGbString(ResourceUsage.swapUsed) + " / " + ResourceUsage.maxAvailableSwapString : qsTr("none") },
        { label: qsTr("Disk"), frac: root.diskFrac, value: root.diskLabel },
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        EditorialSectionHead { title: qsTr("By the Numbers") }

        Repeater {
            model: root.gauges
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 3
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: modelData.label
                        font.family: Editorial.serifFont
                        font.capitalization: Font.SmallCaps
                        font.letterSpacing: 1
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Editorial.ink
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: modelData.value
                        font.family: Editorial.bodyFont
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Editorial.inkMuted
                    }
                }
                Rectangle { // gauge track
                    Layout.fillWidth: true
                    implicitHeight: 6
                    color: Editorial.rule
                    opacity: 0.5
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, modelData.frac))
                        height: parent.height
                        color: Editorial.ink
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        // Footer almanac — uptime + system
        Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; implicitHeight: 1; color: Editorial.rule }
        Repeater {
            model: [
                { label: qsTr("Uptime"),  value: DateTime.uptime },
                { label: qsTr("System"),  value: SystemInfo.distroName + "  ·  " + SystemInfo.username },
            ]
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                StyledText {
                    text: modelData.label
                    font.family: Editorial.serifFont
                    font.capitalization: Font.SmallCaps
                    font.letterSpacing: 1
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Editorial.ink
                    Layout.fillWidth: true
                }
                StyledText {
                    text: modelData.value
                    font.family: Editorial.bodyFont
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Editorial.inkMuted
                    elide: Text.ElideRight
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
