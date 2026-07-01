import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell.Services.Notifications

RippleButton {
    id: button
    property string buttonText
    property string urgency
    readonly property bool critical: urgency == NotificationUrgency.Critical

    implicitHeight: 34
    leftPadding: 15
    rightPadding: 15
    rippleEnabled: false  // mechanical key, not Material ripple
    buttonRadius: Appearance.rounding.verysmall
    buttonRadiusPressed: Math.max(2, Appearance.rounding.verysmall - 2)
    // Raised plastic keys sitting on the recessed card; critical actions glow red.
    colBackground: critical ? ColorUtils.transparentize(DoorwayPalette.redBright, 0.82) : DoorwayPalette.plasticShellTop
    colBackgroundHover: critical ? ColorUtils.transparentize(DoorwayPalette.redBright, 0.68) : Qt.lighter(DoorwayPalette.plasticShellTop, 1.18)

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: critical ? DoorwayPalette.redBright : DoorwayPalette.agedPaper
    }
}