import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            accentColor: DoorwayPalette.koholintGrass
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        // Network gauge: outer ring = downlink, inner ring = uplink — the two rates spin
        // in opposition, mirroring the memory/CPU dials while carrying both directions.
        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.netDownPercentage
            innerPercentage: ResourceUsage.netUpPercentage
            activity: Math.max(ResourceUsage.netDownPercentage, ResourceUsage.netUpPercentage)
            accentColor: DoorwayPalette.netAccent
            shown: Config.options.bar.resources.alwaysShowNetwork ||
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
        }

        Resource {
            iconName: "deployed_code"
            percentage: ResourceUsage.cpuUsage
            accentColor: DoorwayPalette.redBright
            shown: Config.options.bar.resources.alwaysShowCpu ||
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
